# frozen_string_literal: true

module Upgrades
  class Executor
    def initialize(plan:, safety_gate:, registry:, store: ExecutionStore.new,
      lock: Installation::ExecutionLock.new(path: Rails.root.join("var/upgrade/execution.lock")),
      clock: -> { Time.current.utc })
      @plan, @safety_gate, @registry, @store, @lock, @clock = plan, safety_gate, registry, store, lock, clock
    end

    def execute!
      safety_gate.authorize!
      lock.synchronize do
        state = resumable_state
        plan.operations.each do |operation|
          next if completed?(state, operation)
          record!(state, operation, "running")
          registry.execute(operation)
          record!(state, operation, "completed")
        rescue StandardError => error
          record!(
            state,
            operation,
            "failed",
            error: error.class.name,
            failure_code: "operation_failed"
          )
          raise OperationFailed, "upgrade operation failed"
        end
        state["status"] = "completed"
        state["completed_at"] = clock.call.iso8601
        store.write!(state)
      end
    end

    private

    attr_reader :plan, :safety_gate, :registry, :store, :lock, :clock

    def resumable_state
      existing = store.read
      return existing if existing && existing["manifest_id"] == plan.manifest_id
      {
        "schema_version" => 1, "manifest_id" => plan.manifest_id,
        "source_version" => plan.source_version, "target_version" => plan.target_version,
        "status" => "running", "started_at" => clock.call.iso8601, "operations" => []
      }
    end

    def completed?(state, operation)
      state["operations"].any? { |item| item["id"] == operation.fetch("id") && item["status"] == "completed" }
    end

    def record!(state, operation, status, error: nil, failure_code: nil)
      state["operations"].reject! { |item| item["id"] == operation.fetch("id") }
      state["operations"] << {
        "id" => operation.fetch("id"), "status" => status,
        "occurred_at" => clock.call.iso8601, "error" => error,
        "failure_code" => failure_code
      }
      state["status"] = status == "failed" ? "failed" : "running"
      store.write!(state)
    end

    class OperationFailed < StandardError; end
  end
end

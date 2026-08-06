# frozen_string_literal: true

module OperationalReadiness
  class RestoreExecutor
    def initialize(manifest:, plan:, safety_gate:, registry:, checksum_verifier:,
      lock: Installation::ExecutionLock.new(path: Rails.root.join("var/restore/execution.lock")),
      clock: -> { Time.current.utc })
      @manifest = manifest
      @plan = plan
      @safety_gate = safety_gate
      @registry = registry
      @checksum_verifier = checksum_verifier
      @lock = lock
      @clock = clock
    end

    def execute!
      safety_gate.authorize!
      lock.synchronize do
        verify_checksums!
        completed = plan.ordered_steps.map do |step|
          component = component_for(step.fetch("component"))
          registry.restore(component:, step:, target: plan.target)
          {
            "id" => step.fetch("id"),
            "component" => component.fetch("kind"),
            "status" => "completed"
          }
        end
        {
          "schema_version" => 1,
          "backup_manifest_id" => manifest.id,
          "restore_plan_id" => plan.id,
          "status" => "completed",
          "completed_at" => clock.call.iso8601,
          "steps" => completed
        }
      end
    rescue RestoreSafetyGate::UnsafeRestore, ChecksumMismatch, RestoreAdapterRegistry::AdapterUnavailable
      raise
    rescue StandardError
      raise RestoreFailed, "restore execution failed"
    end

    private

    attr_reader :manifest, :plan, :safety_gate, :registry, :checksum_verifier, :lock, :clock

    def component_for(kind)
      manifest.components.find { |component| component.fetch("kind") == kind } ||
        raise(RestoreFailed, "restore component is unavailable")
    end

    def verify_checksums!
      manifest.components.each do |component|
        next if checksum_verifier.call(component)

        raise ChecksumMismatch, "backup component checksum verification failed"
      end
    end

    class ChecksumMismatch < StandardError; end
    class RestoreFailed < StandardError; end
  end
end

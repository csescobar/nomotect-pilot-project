# frozen_string_literal: true

require "test_helper"

module Upgrades
  class ExecutorTest < ActiveSupport::TestCase
    test "resumes idempotently after a failed registered operation" do
      Dir.mktmpdir do |directory|
        store = ExecutionStore.new(path: File.join(directory, "execution.json"))
        calls = []
        registry = OperationRegistry.new.register("one") { calls << "one" }
        failures = 0
        registry.register("two") { failures += 1; raise "temporary" if failures == 1; calls << "two" }
        executor = Executor.new(plan: plan, safety_gate: safety_gate, registry:, store:, lock: lock(directory))

        assert_raises(Executor::OperationFailed) { executor.execute! }
        executor.execute!

        assert_equal %w[one two], calls
        assert_equal "completed", store.read.fetch("status")
      end
    end

    private

    def plan
      operation = ->(id) { { "id" => id, "type" => "configuration", "description" => id, "reversible" => true, "requires" => [] } }
      Planner::Plan.new("manifest-1", "0.4.0", "0.5.0", true, %w[one two].map(&operation), [])
    end

    def safety_gate
      Object.new.tap { |item| item.define_singleton_method(:authorize!) { true } }
    end

    def lock(directory)
      Installation::ExecutionLock.new(path: File.join(directory, "execution.lock"))
    end
  end
end

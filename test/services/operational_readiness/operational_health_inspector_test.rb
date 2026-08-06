# frozen_string_literal: true

require "test_helper"

module OperationalReadiness
  class OperationalHealthInspectorTest < ActiveSupport::TestCase
    test "aggregates required and optional providers deterministically" do
      registry = HealthProviderRegistry.new
        .register("installation", category: "installation", required: true) { result("healthy", "installation_ready") }
        .register("storage", category: "storage", required: true) { result("healthy", "storage_ready") }
        .register("webhook", category: "integrations", required: false) { result("unhealthy", "integration_unavailable") }

      snapshot = inspector(registry).call

      assert_equal "degraded", snapshot.fetch("status")
      assert_equal %w[installation storage webhook], snapshot.fetch("signals").pluck("id")
      assert_equal 1, snapshot.dig("summary", "unhealthy")
    end

    test "isolates timeout and redacts provider details" do
      registry = HealthProviderRegistry.new
        .register("jobs", category: "jobs", required: false) { sleep 0.05 }
        .register("storage", category: "storage", required: true) do
          result("healthy", "storage_ready", "database_url" => "postgresql://user:password@db/app")
        end

      snapshot = inspector(registry, timeout: 0.01).call
      serialized = JSON.generate(snapshot)

      assert_equal "degraded", snapshot.fetch("status")
      assert_equal "health_provider_timeout", snapshot.fetch("signals").first.fetch("code")
      refute_includes serialized, "user:password"
    end

    private

    def inspector(registry, timeout: 1)
      tick = 0
      OperationalHealthInspector.new(
        registry:,
        timeout:,
        clock: -> { Time.iso8601("2026-07-31T01:00:00Z") },
        monotonic_clock: -> { tick += 0.001 }
      )
    end

    def result(status, code, details = {})
      { "status" => status, "code" => code, "details" => details, "operator_actions" => [] }
    end
  end
end

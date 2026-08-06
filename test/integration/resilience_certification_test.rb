# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class ResilienceCertificationTest < ActiveSupport::TestCase
  test "certifies all production-like resilience scenarios without escaping the fixture" do
    Dir.mktmpdir("resilience-", Rails.root.join("tmp")) do |directory|
      injector = OperationalReadiness::SafeFaultInjector.new(root: directory, environment: "production-like")
      registry = OperationalReadiness::ResilienceScenarioRegistry.new
      OperationalReadiness::ResilienceScenarioRegistry::REQUIRED_IDS.each do |id|
        registry.register(id) do
          injector.write("#{id}/before", "available")
          injector.remove("#{id}/before")
          injector.write("#{id}/after", "recovered")
          {
            "status" => "passed",
            "code" => "#{id}_certified",
            "evidence" => { "initial_health" => "healthy", "fault_health" => "degraded", "final_health" => "healthy" }
          }
        end
      end

      report = OperationalReadiness::ResilienceCertificationRunner.new(
        registry:,
        policy: OperationalReadiness::DisasterRecoveryPolicy.load(
          Rails.root.join("config/operations/disaster-recovery.example.json")
        ),
        source_commit: "c" * 40,
        clock: -> { Time.iso8601("2026-07-31T02:00:00Z") }
      ).call

      assert_equal "certified", report.fetch("status")
      assert_equal 8, report.dig("summary", "passed")
      assert_equal OperationalReadiness::ResilienceScenarioRegistry::REQUIRED_IDS.sort,
        report.fetch("scenarios").pluck("id").sort
      assert_raises(OperationalReadiness::SafeFaultInjector::UnsafeFixture) { injector.write("../escape", "blocked") }
    end
  end
end

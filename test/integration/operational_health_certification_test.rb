# frozen_string_literal: true

require "test_helper"

class OperationalHealthCertificationTest < ActiveSupport::TestCase
  test "certifies all operational categories and support-bundle integration" do
    state = {
      "installation" => { "state" => "completed", "contract_version" => 1 },
      "deployment" => { "profile" => "production-like" },
      "extensions" => []
    }
    providers = OperationalReadiness::DefaultHealthProviders.new(installed_state: -> { state }).registry

    assert_equal OperationalReadiness::HealthSignal::CATEGORIES.sort, providers.all.map(&:category).sort

    health = {
      "schema_version" => 1,
      "observed_at" => "2026-07-31T01:00:00Z",
      "status" => "healthy",
      "summary" => { "healthy" => 5, "degraded" => 0, "unhealthy" => 0, "unknown" => 0 },
      "signals" => []
    }
    collectors = OperationalReadiness::DefaultDiagnosticCollectors.new(
      installed_state: -> { state },
      environment: {},
      operational_health: -> { health }
    ).registry

    assert_equal health, collectors.collect.fetch("operational_health")
  end
end

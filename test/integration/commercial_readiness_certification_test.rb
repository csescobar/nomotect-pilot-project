# frozen_string_literal: true

require "test_helper"

class CommercialReadinessCertificationTest < ActiveSupport::TestCase
  test "certifies community operation when every commercial integration is absent" do
    edition = CommercialReadiness::EditionManifest.new(
      YAML.safe_load_file(Rails.root.join("config/editions/community.yml"))
    )
    identity = CommercialReadiness::SupportIdentity.create(
      identifier_generator: -> { "11111111-1111-4111-8111-111111111111" }
    )

    report = CommercialReadiness::Certification.run(
      edition:,
      identity:,
      telemetry_policy: CommercialReadiness::TelemetryPolicy.disabled,
      checked_at: Time.utc(2026, 7, 31, 13)
    )

    assert_equal "passed", report.fetch("status")
    assert_equal 4, report.fetch("checks").size
    assert report.fetch("checks").all? { |check| check.fetch("status") == "passed" }
  end

  test "certifies essential community capabilities when a commercial provider fails" do
    edition = CommercialReadiness::EditionManifest.new(
      YAML.safe_load_file(Rails.root.join("config/editions/community.yml"))
    )
    identity = CommercialReadiness::SupportIdentity.create(
      identifier_generator: -> { "11111111-1111-4111-8111-111111111111" }
    )

    report = CommercialReadiness::Certification.run(
      edition:,
      identity:,
      telemetry_policy: CommercialReadiness::TelemetryPolicy.disabled,
      provider: ->(_) { raise "commercial service unavailable" }
    )

    assert_equal "passed", report.fetch("status")
    assert_equal "passed", check(report, "community_capabilities").fetch("status")
    assert_equal "passed", check(report, "unknown_capabilities_fail_closed").fetch("status")
  end

  private

  def check(report, id)
    report.fetch("checks").find { |item| item.fetch("id") == id }
  end
end

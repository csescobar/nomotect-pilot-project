# frozen_string_literal: true

require "test_helper"

module CommercialReadiness
  class TelemetryPolicyTest < ActiveSupport::TestCase
    test "telemetry is disabled by default and produces no envelope" do
      policy = TelemetryPolicy.disabled

      assert_not policy.enabled?
      assert_nil TelemetryEnvelope.build(policy:, category: "capability_usage", attributes: { capability: "grid" })
    end

    test "explicit consent limits collection to selected categories" do
      policy = TelemetryPolicy.disabled.enable(
        categories: [ "capability_usage" ],
        at: Time.utc(2026, 7, 31, 10)
      )

      envelope = TelemetryEnvelope.build(
        policy:,
        category: "capability_usage",
        attributes: { capability: "grid", result: "available" },
        collected_at: Time.utc(2026, 7, 31, 10, 1)
      )

      assert_equal({ "capability" => "grid", "result" => "available" }, envelope.fetch("attributes"))
      assert_nil TelemetryEnvelope.build(policy:, category: "operational_health", attributes: { status: "ok" })
    end

    test "envelopes transparently report fields removed by the allowlist" do
      policy = TelemetryPolicy.disabled.enable(categories: [ "operational_health" ])
      envelope = TelemetryEnvelope.build(
        policy:,
        category: "operational_health",
        attributes: { category: "jobs", status: "ok", duration_ms: 4, email: "person@example.com", token: "secret" }
      )

      assert_equal %w[email token], envelope.fetch("redacted_fields")
      assert_equal %w[category duration_ms status], envelope.fetch("attributes").keys.sort
    end

    test "disablement takes effect immediately and clears consented categories" do
      policy = TelemetryPolicy.disabled.enable(categories: TelemetryPolicy::CATEGORIES).disable

      assert_not policy.enabled?
      assert_empty policy.categories
      assert_nil TelemetryEnvelope.build(policy:, category: "operational_health", attributes: { status: "ok" })
    end

    test "rejects unknown categories and categories retained while disabled" do
      assert_raises(TelemetryPolicy::InvalidPolicy) do
        TelemetryPolicy.disabled.enable(categories: [ "tenant_data" ])
      end
      assert_raises(TelemetryPolicy::InvalidPolicy) do
        TelemetryPolicy.new(TelemetryPolicy.disabled.data.merge("categories" => [ "capability_usage" ]))
      end
    end
  end
end

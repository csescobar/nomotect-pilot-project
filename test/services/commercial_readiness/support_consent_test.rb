# frozen_string_literal: true

require "test_helper"

module CommercialReadiness
  class SupportConsentTest < ActiveSupport::TestCase
    SUPPORT_ID = "22222222-2222-4222-8222-222222222222"
    INSTALLATION_ID = "11111111-1111-4111-8111-111111111111"
    NOW = Time.utc(2026, 7, 31, 12)

    test "grants only explicit time-bounded diagnostic scopes" do
      consent = SupportConsent.grant(
        support_id: SUPPORT_ID,
        scopes: [ "diagnostics" ],
        granted_at: NOW,
        expires_at: NOW + 1.hour
      )

      assert consent.allows?("diagnostics", at: NOW)
      assert_not consent.allows?("operational_health", at: NOW)
      assert_not consent.active?(at: NOW + 1.hour)
    end

    test "revocation takes effect immediately" do
      consent = SupportConsent.grant(
        support_id: SUPPORT_ID,
        scopes: SupportConsent::SCOPES,
        granted_at: NOW,
        expires_at: NOW + 1.day
      ).revoke(at: NOW + 1.minute)

      assert consent.revoked?
      assert_not consent.allows?("diagnostics", at: NOW + 2.minutes)
    end

    test "share plans include only consented artifacts and require operator upload" do
      identity = SupportIdentity.create(identifier_generator: -> { INSTALLATION_ID })
        .enable_support(identifier_generator: -> { SUPPORT_ID })
      consent = SupportConsent.grant(
        support_id: SUPPORT_ID,
        scopes: [ "diagnostics", "operational_health" ],
        granted_at: NOW,
        expires_at: NOW + 1.hour
      )

      plan = SupportSharePlan.build(
        identity:,
        consent:,
        requested_artifacts: [ "support_bundle", "health_snapshot", "redacted_configuration", "database_dump" ],
        at: NOW
      )

      assert_equal %w[health_snapshot support_bundle], plan.artifacts
      assert plan.requires_operator_upload
    end

    test "rejects mismatched support relationships and invalid scopes" do
      identity = SupportIdentity.create(identifier_generator: -> { INSTALLATION_ID })
        .enable_support(identifier_generator: -> { SUPPORT_ID })
      other_consent = SupportConsent.grant(
        support_id: "33333333-3333-4333-8333-333333333333",
        scopes: [ "diagnostics" ],
        granted_at: NOW,
        expires_at: NOW + 1.hour
      )

      assert_raises(SupportSharePlan::ConsentMismatch) do
        SupportSharePlan.build(identity:, consent: other_consent, requested_artifacts: [ "support_bundle" ], at: NOW)
      end
      assert_raises(SupportConsent::InvalidConsent) do
        SupportConsent.grant(
          support_id: SUPPORT_ID,
          scopes: [ "raw_database" ],
          granted_at: NOW,
          expires_at: NOW + 1.hour
        )
      end
    end
  end
end

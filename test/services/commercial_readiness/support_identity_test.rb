# frozen_string_literal: true

require "test_helper"

module CommercialReadiness
  class SupportIdentityTest < ActiveSupport::TestCase
    IDENTIFIERS = %w[
      11111111-1111-4111-8111-111111111111
      22222222-2222-4222-8222-222222222222
      33333333-3333-4333-8333-333333333333
      44444444-4444-4444-8444-444444444444
    ].freeze

    test "creates a local installation identity without enabling support" do
      identity = SupportIdentity.create(identifier_generator: -> { IDENTIFIERS.first })

      assert_equal IDENTIFIERS.first, identity.installation_id
      assert_nil identity.support_id
      assert_nil identity.customer_id
      assert_not identity.support_enabled?
    end

    test "enables rotates and disables opaque support identities explicitly" do
      identity = SupportIdentity.create(identifier_generator: -> { IDENTIFIERS[0] })
      identity = identity.enable_support(
        customer_id: IDENTIFIERS[1],
        identifier_generator: -> { IDENTIFIERS[2] }
      )

      assert identity.support_enabled?
      assert_equal IDENTIFIERS[1], identity.customer_id
      assert_equal IDENTIFIERS[2], identity.support_id

      rotated = identity.rotate_support(
        at: Time.utc(2026, 7, 31, 1, 30),
        identifier_generator: -> { IDENTIFIERS[3] }
      )

      assert_equal IDENTIFIERS[0], rotated.installation_id
      assert_equal IDENTIFIERS[3], rotated.support_id
      assert_equal "2026-07-31T01:30:00Z", rotated.data.fetch("rotated_at")
      assert_nil rotated.disable_support.support_id
      assert_nil rotated.disable_support.customer_id
    end

    test "rejects personal data and non-opaque identifiers" do
      invalid = SupportIdentity.create(identifier_generator: -> { IDENTIFIERS.first }).as_json.merge(
        "customer_id" => "person@example.com",
        "support_id" => IDENTIFIERS[1]
      )

      assert_raises(SupportIdentity::InvalidIdentity) { SupportIdentity.new(invalid) }
      assert_raises(SupportIdentity::InvalidIdentity) do
        SupportIdentity.new(invalid.merge("email" => "person@example.com"))
      end
    end

    test "requires support consent for customer and rotation metadata" do
      base = SupportIdentity.create(identifier_generator: -> { IDENTIFIERS.first }).as_json

      assert_raises(SupportIdentity::InvalidIdentity) do
        SupportIdentity.new(base.merge("customer_id" => IDENTIFIERS[1]))
      end
      assert_raises(SupportIdentity::InvalidIdentity) do
        SupportIdentity.new(base.merge("rotated_at" => "2026-07-31T01:30:00Z"))
      end
    end
  end
end

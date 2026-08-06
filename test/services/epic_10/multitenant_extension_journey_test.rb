# frozen_string_literal: true

require "test_helper"

module Epic10
  class MultitenantExtensionJourneyTest < ActiveSupport::TestCase
    test "loads isolated tenants community fallback and extension lifecycle" do
      journey = load_journey
      assert_equal "denied", journey.data.dig("tenants", "cross_tenant_access")
      assert journey.data.dig("community", "operates_without_extensions")
      assert_equal %w[discovered verified loaded ready disabled], journey.data.dig("extension", "lifecycle")
      assert_predicate journey.data, :frozen?
    end

    test "rejects cross-tenant access and overprivileged members" do
      data = journey_data
      data.fetch("tenants")["cross_tenant_access"] = "allowed"
      assert_raises(MultitenantExtensionJourney::InvalidJourney) { build(data) }

      data = journey_data
      data.dig("permissions", "member") << "manage_requests"
      assert_raises(MultitenantExtensionJourney::InvalidJourney) { build(data) }
    end

    test "rejects community dependency and unsafe extension failure" do
      data = journey_data
      data.fetch("community")["operates_without_extensions"] = false
      assert_raises(MultitenantExtensionJourney::InvalidJourney) { build(data) }

      data = journey_data
      data.fetch("extension")["may_disable_community"] = true
      assert_raises(MultitenantExtensionJourney::InvalidJourney) { build(data) }
    end

    private

    def load_journey = MultitenantExtensionJourney.load(Rails.root.join("test/support/representative_application/multitenant_extension.yml"))
    def journey_data = YAML.safe_load_file(Rails.root.join("test/support/representative_application/multitenant_extension.yml"), aliases: false)
    def build(data) = MultitenantExtensionJourney.new(data)
  end
end

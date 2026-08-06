# frozen_string_literal: true

require "test_helper"

module Epic10
  class DomainServicesJourneyTest < ActiveSupport::TestCase
    test "loads governed domain lifecycle and tenant-safe services" do
      journey = load_journey
      assert_equal %w[submitted triaged in_progress resolved], journey.data.fetch("states")
      assert journey.data.dig("services", "background_job", "idempotent")
      assert journey.data.dig("services", "file", "checksum_required")
      assert_predicate journey.data, :frozen?
    end

    test "rejects policy bypass and non-idempotent work" do
      data = journey_data
      data.fetch("transitions").first["policy"] = "none"
      assert_raises(DomainServicesJourney::InvalidJourney) { build(data) }

      data = journey_data
      data.dig("services", "background_job")["idempotent"] = false
      assert_raises(DomainServicesJourney::InvalidJourney) { build(data) }
    end

    test "rejects cross-tenant service configuration and incomplete evidence" do
      data = journey_data
      data.dig("services", "notification")["tenant_scoped"] = false
      assert_raises(DomainServicesJourney::InvalidJourney) { build(data) }

      data = journey_data
      data.fetch("evidence")["policy_denial"] = "optional"
      assert_raises(DomainServicesJourney::InvalidJourney) { build(data) }
    end

    private

    def load_journey = DomainServicesJourney.load(Rails.root.join("test/support/representative_application/domain_services.yml"))
    def journey_data = YAML.safe_load_file(Rails.root.join("test/support/representative_application/domain_services.yml"), aliases: false)
    def build(data) = DomainServicesJourney.new(data)
  end
end

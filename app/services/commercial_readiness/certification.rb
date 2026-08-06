# frozen_string_literal: true

module CommercialReadiness
  class Certification
    Check = Data.define(:id, :status, :detail)

    def self.run(edition:, identity:, telemetry_policy:, provider: nil, checked_at: Time.current)
      new(
        edition:,
        identity:,
        telemetry_policy:,
        provider:,
        checked_at:
      ).run
    end

    def initialize(edition:, identity:, telemetry_policy:, provider:, checked_at:)
      @edition = edition
      @identity = identity
      @telemetry_policy = telemetry_policy
      @provider = provider
      @checked_at = checked_at
    end

    def run
      checks = [
        community_capabilities_check,
        unknown_capability_check,
        optional_support_check,
        telemetry_default_check
      ]

      {
        "schema_version" => 1,
        "status" => checks.all? { |check| check.status == "passed" } ? "passed" : "failed",
        "checked_at" => checked_at.utc.iso8601,
        "checks" => checks.map { |check| check.to_h.stringify_keys }
      }.freeze
    end

    private

    attr_reader :edition, :identity, :telemetry_policy, :provider, :checked_at

    def resolver
      @resolver ||= EntitlementResolver.new(edition:, provider:)
    end

    def community_capabilities_check
      unavailable = EditionManifest::COMMUNITY_CAPABILITIES.reject do |capability|
        resolver.resolve(capability).status == "available"
      end
      check("community_capabilities", unavailable.empty?, "unavailable=#{unavailable.join(',')}")
    end

    def unknown_capability_check
      result = resolver.resolve("unknown_commercial_capability")
      check("unknown_capabilities_fail_closed", result.status == "unavailable", "status=#{result.status}")
    end

    def optional_support_check
      valid = !identity.support_enabled? && identity.customer_id.nil?
      check("support_is_optional", valid, "support_enabled=#{identity.support_enabled?}")
    end

    def telemetry_default_check
      valid = !telemetry_policy.enabled? && telemetry_policy.categories.empty?
      check("telemetry_is_opt_in", valid, "enabled=#{telemetry_policy.enabled?}")
    end

    def check(id, passed, detail)
      Check.new(id:, status: passed ? "passed" : "failed", detail:)
    end
  end
end

# frozen_string_literal: true

module CommercialReadiness
  class EditionManifest
    COMMUNITY_EDITION = "community"
    COMMUNITY_CAPABILITIES = %w[
      installation authentication authorization tenancy design_system grid_engine
      domain_framework enterprise_services repository_intelligence extensions
      upgrades releases distribution operational_readiness
    ].freeze

    attr_reader :data

    def initialize(data)
      @data = data
      validate!
      deep_freeze(@data)
    end

    def id = data.fetch("id")
    def capabilities = data.fetch("capabilities")

    private

    def validate!
      keys = %w[schema_version id capabilities]
      raise InvalidManifest, "edition manifest fields are invalid" unless data.is_a?(Hash) && data.keys.sort == keys.sort
      raise InvalidManifest, "unsupported edition manifest schema" unless data["schema_version"] == 1
      raise InvalidManifest, "community edition is required" unless data["id"] == COMMUNITY_EDITION
      missing = COMMUNITY_CAPABILITIES - data["capabilities"]
      raise InvalidManifest, "community capabilities cannot be removed" if missing.any?
    end

    def deep_freeze(value)
      value.each { |key, item| deep_freeze(key); deep_freeze(item) } if value.is_a?(Hash)
      value.each { |item| deep_freeze(item) } if value.is_a?(Array)
      value.freeze
    end

    class InvalidManifest < StandardError; end
  end
end

# frozen_string_literal: true

module CommercialReadiness
  class TelemetryPolicy
    SCHEMA_VERSION = 1
    CATEGORIES = %w[capability_usage operational_health].freeze
    FIELDS = %w[schema_version enabled categories updated_at].freeze

    attr_reader :data

    def self.disabled
      new("schema_version" => SCHEMA_VERSION, "enabled" => false, "categories" => [], "updated_at" => nil)
    end

    def initialize(data)
      @data = data
      validate!
      @data = data.freeze
    end

    def enabled? = data.fetch("enabled")
    def categories = data.fetch("categories")
    def allows?(category) = enabled? && categories.include?(category.to_s)

    def enable(categories:, at: Time.current)
      self.class.new(data.merge("enabled" => true, "categories" => categories.map(&:to_s).uniq.sort, "updated_at" => at.utc.iso8601))
    end

    def disable(at: Time.current)
      self.class.new(data.merge("enabled" => false, "categories" => [], "updated_at" => at.utc.iso8601))
    end

    private

    def validate!
      raise InvalidPolicy, "telemetry policy fields are invalid" unless data.is_a?(Hash) && data.keys.sort == FIELDS.sort
      raise InvalidPolicy, "unsupported telemetry policy schema" unless data["schema_version"] == SCHEMA_VERSION
      raise InvalidPolicy, "enabled must be boolean" unless [ true, false ].include?(data["enabled"])
      raise InvalidPolicy, "telemetry categories are invalid" unless data["categories"].is_a?(Array) && (data["categories"] - CATEGORIES).empty?
      raise InvalidPolicy, "disabled telemetry cannot retain categories" if !data["enabled"] && data["categories"].any?
    end

    class InvalidPolicy < StandardError; end
  end
end

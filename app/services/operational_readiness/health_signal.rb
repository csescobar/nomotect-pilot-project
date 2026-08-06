# frozen_string_literal: true

module OperationalReadiness
  class HealthSignal
    STATUSES = %w[healthy degraded unhealthy unknown].freeze
    CATEGORIES = %w[installation deployment jobs storage integrations].freeze

    attr_reader :data

    def initialize(data)
      @data = data
      validate!
      deep_freeze(@data)
    end

    def deep_freeze(value)
      value.each { |key, item| deep_freeze(key); deep_freeze(item) } if value.is_a?(Hash)
      value.each { |item| deep_freeze(item) } if value.is_a?(Array)
      value.freeze
    end

    def status = data.fetch("status")
    def required? = data.fetch("required")
    def category = data.fetch("category")

    private

    def validate!
      keys = %w[id category required status code observed_at duration_ms details operator_actions]
      raise InvalidSignal, "health signal fields are invalid" unless data.is_a?(Hash) && data.keys.sort == keys.sort
      raise InvalidSignal, "health signal category is invalid" unless CATEGORIES.include?(data["category"])
      raise InvalidSignal, "health signal status is invalid" unless STATUSES.include?(data["status"])
      raise InvalidSignal, "health signal required flag is invalid" unless [ true, false ].include?(data["required"])
      raise InvalidSignal, "health signal duration is invalid" unless data["duration_ms"].is_a?(Integer) && data["duration_ms"] >= 0
      raise InvalidSignal, "health signal details are invalid" unless data["details"].is_a?(Hash)
      raise InvalidSignal, "health signal operator actions are invalid" unless data["operator_actions"].is_a?(Array)
      %w[id code observed_at].each { |key| raise InvalidSignal, "#{key} is required" unless data[key].is_a?(String) && data[key].present? }
      Time.iso8601(data.fetch("observed_at"))
    rescue ArgumentError
      raise InvalidSignal, "health signal timestamp is invalid"
    end

    class InvalidSignal < StandardError; end
  end
end

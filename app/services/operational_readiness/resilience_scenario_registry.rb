# frozen_string_literal: true

module OperationalReadiness
  class ResilienceScenarioRegistry
    REQUIRED_IDS = %w[
      application_restart node_replacement backup_certification restore_certification
      degraded_job_backend degraded_integration storage_degradation partial_restore_failure
    ].freeze
    Scenario = Data.define(:id, :callable)

    def initialize
      @scenarios = {}
    end

    def register(id, &scenario)
      id = id.to_s
      raise InvalidScenario, "resilience scenario is unsupported" unless REQUIRED_IDS.include?(id)
      raise InvalidScenario, "resilience scenario block is required" unless scenario
      raise InvalidScenario, "resilience scenario is already registered" if scenarios.key?(id)

      scenarios[id] = Scenario.new(id:, callable: scenario)
      self
    end

    def all
      missing = REQUIRED_IDS - scenarios.keys
      raise InvalidScenario, "resilience scenario registry is incomplete" if missing.any?

      scenarios.values.sort_by(&:id)
    end

    private

    attr_reader :scenarios

    class InvalidScenario < StandardError; end
  end
end

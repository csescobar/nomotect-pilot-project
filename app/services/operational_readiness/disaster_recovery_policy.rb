# frozen_string_literal: true

require "json"

module OperationalReadiness
  class DisasterRecoveryPolicy
    SCHEMA_VERSION = 1
    REQUIRED_SCENARIOS = %w[
      application_restart node_replacement database_unavailable database_loss
      persistent_storage_loss configuration_loss job_backend_unavailable
      integration_unavailable partial_restore_failure complete_environment_loss
    ].freeze
    REQUIRED_ROLES = %w[incident_commander recovery_operator security_reviewer application_owner].freeze

    attr_reader :data

    def self.load(path)
      new(JSON.parse(File.read(path)))
    rescue JSON::ParserError
      raise InvalidPolicy, "disaster recovery policy is not valid JSON"
    end

    def initialize(data)
      @data = data
      validate!
      deep_freeze(@data)
    end

    def readiness
      findings = []
      findings << "objectives_incomplete" unless %w[rto_minutes rpo_minutes].all? { |key| positive?(data.dig("objectives", key)) }
      findings << "roles_incomplete" if (REQUIRED_ROLES - data.fetch("roles").keys).any?
      findings << "scenarios_incomplete" if (REQUIRED_SCENARIOS - data.fetch("scenarios").pluck("id")).any?
      { "status" => findings.empty? ? "ready" : "blocked", "ready" => findings.empty?, "findings" => findings }
    end

    private

    def validate!
      keys = %w[schema_version id environment objectives scope roles scenarios evidence approval]
      raise InvalidPolicy, "disaster recovery policy fields are invalid" unless data.is_a?(Hash) && data.keys.sort == keys.sort
      raise InvalidPolicy, "unsupported disaster recovery policy schema" unless data["schema_version"] == SCHEMA_VERSION
      raise InvalidPolicy, "disaster recovery scenarios must be an array" unless data["scenarios"].is_a?(Array)
      raise InvalidPolicy, "disaster recovery roles must be an object" unless data["roles"].is_a?(Hash)
      raise InvalidPolicy, "automatic destructive restore is prohibited" unless data.dig("approval", "restore") == "human_required"
      raise InvalidPolicy, "automatic return to service is prohibited" unless data.dig("approval", "return_to_service") == "human_required"
    end

    def positive?(value) = value.is_a?(Integer) && value.positive?

    def deep_freeze(value)
      value.each { |key, item| deep_freeze(key); deep_freeze(item) } if value.is_a?(Hash)
      value.each { |item| deep_freeze(item) } if value.is_a?(Array)
      value.freeze
    end

    class InvalidPolicy < StandardError; end
  end
end

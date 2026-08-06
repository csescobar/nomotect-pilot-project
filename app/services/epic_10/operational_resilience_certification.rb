# frozen_string_literal: true

require "yaml"

module Epic10
  class OperationalResilienceCertification
    class InvalidCertification < StandardError; end

    REQUIRED_SCENARIOS = %w[process_restart application_replacement database_unavailable storage_unavailable integration_unavailable backup_restore].freeze
    REQUIRED_EVIDENCE = %w[health_before fault_observed credential_free_backup restored_state_checksum health_after operator_guidance].freeze

    def initialize(source_commit:, path: Rails.root.join("config/epic_10/operational-resilience.yml"))
      @source_commit = String(source_commit)
      @path = Pathname(path)
    end

    def call
      raise InvalidCertification, "source commit must be a full lowercase SHA" unless /\A[0-9a-f]{40}\z/.match?(source_commit)
      data = YAML.safe_load_file(path, aliases: false)
      scenarios = Array(data.fetch("scenarios"))
      raise InvalidCertification, "resilience scenarios are incomplete" unless scenarios.pluck("id") == REQUIRED_SCENARIOS
      raise InvalidCertification, "recovery is not verified" unless scenarios.all? { |scenario| scenario["recovery"] == "verified" }
      raise InvalidCertification, "recovery evidence is incomplete" unless data.fetch("required_evidence") == REQUIRED_EVIDENCE
      evidence = data.fetch("evidence")
      raise InvalidCertification, "resilience evidence must fail closed" unless %w[deterministic credential_free persistent_state_verified source_commit_required].all? { |key| evidence[key] == true }
      raise InvalidCertification, "production data is forbidden" unless evidence["production_data"] == false
      raise InvalidCertification, "certification cannot publish" unless data.dig("publication", "allowed") == false

      {
        "schema_version" => 1, "phase" => 5, "status" => "passed",
        "source_commit" => source_commit,
        "scenarios" => scenarios.map { |scenario| { "id" => scenario.fetch("id"), "status" => "passed", "recovery" => scenario.fetch("recovery") } },
        "required_evidence" => REQUIRED_EVIDENCE,
        "credential_free" => true,
        "publication" => { "allowed" => false }
      }
    rescue KeyError, Psych::Exception, Errno::ENOENT => error
      raise InvalidCertification, error.message
    end

    private

    attr_reader :source_commit, :path
  end
end

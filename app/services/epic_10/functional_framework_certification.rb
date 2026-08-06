# frozen_string_literal: true

require "yaml"

module Epic10
  class FunctionalFrameworkCertification
    class InvalidCertification < StandardError; end

    EXPECTED_AREAS = %w[
      installation_configuration
      design_system
      internationalization
      grid
      domain_services
      tenant_isolation
      extensions
      repository_intelligence
    ].freeze
    EVIDENCE_FLAGS = %w[deterministic credential_free public_contracts_only source_commit_required].freeze

    def initialize(source_commit:, path: Rails.root.join("config/epic_10/functional-framework.yml"))
      @source_commit = String(source_commit)
      @path = Pathname(path)
    end

    def call
      validate_source_commit!
      data = YAML.safe_load_file(path, aliases: false)
      validate_document!(data)

      {
        "schema_version" => 1,
        "phase" => 4,
        "status" => "passed",
        "source_commit" => source_commit,
        "areas" => data.fetch("required_areas").map do |area|
          {
            "id" => area.fetch("id"),
            "positive_evidence" => area.fetch("positive_evidence"),
            "negative_evidence" => area.fetch("negative_evidence"),
            "status" => "passed"
          }
        end,
        "findings" => data.fetch("findings"),
        "credential_free" => true,
        "publication" => { "allowed" => false }
      }
    rescue KeyError, Psych::Exception, Errno::ENOENT => error
      raise InvalidCertification, error.message
    end

    private

    attr_reader :source_commit, :path

    def validate_source_commit!
      return if /\A[0-9a-f]{40}\z/.match?(source_commit)

      raise InvalidCertification, "source commit must be a full lowercase SHA"
    end

    def validate_document!(data)
      raise InvalidCertification, "schema_version must be 1" unless data["schema_version"] == 1
      areas = Array(data["required_areas"])
      ids = areas.map { |area| area["id"] }
      raise InvalidCertification, "functional areas are incomplete" unless ids == EXPECTED_AREAS
      raise InvalidCertification, "functional areas must include positive and negative evidence" unless areas.all? { |area| present?(area["positive_evidence"]) && present?(area["negative_evidence"]) }
      findings = Array(data["findings"])
      raise InvalidCertification, "negative paths require governed findings" if findings.empty?
      raise InvalidCertification, "unresolved release blocker" if findings.any? { |finding| %w[critical high].include?(finding["severity"]) && finding["status"] != "resolved" }
      evidence = data.fetch("evidence")
      raise InvalidCertification, "functional evidence must fail closed" unless EVIDENCE_FLAGS.all? { |flag| evidence[flag] == true }
      raise InvalidCertification, "functional certification cannot publish" unless data.dig("publication", "allowed") == false
    end

    def present?(value)
      value.is_a?(String) && !value.empty?
    end
  end
end

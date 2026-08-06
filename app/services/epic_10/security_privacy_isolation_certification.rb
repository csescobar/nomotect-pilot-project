# frozen_string_literal: true

require "yaml"

module Epic10
  class SecurityPrivacyIsolationCertification
    class InvalidCertification < StandardError; end

    REQUIRED = %w[authorization tenant_isolation content_security_policy abuse_controls dependency_audit secret_scanning supply_chain adversarial_inputs data_minimization log_redaction retention_policy subject_workflows].freeze
    ZERO_THRESHOLDS = %w[unresolved_critical unresolved_high cross_tenant_leaks secret_bearing_evidence].freeze

    def initialize(source_commit:, path: Rails.root.join("config/epic_10/security-privacy-isolation.yml"))
      @source_commit = String(source_commit)
      @path = Pathname(path)
    end

    def call
      raise InvalidCertification, "source commit must be a full lowercase SHA" unless /\A[0-9a-f]{40}\z/.match?(source_commit)
      data = YAML.safe_load_file(path, aliases: false)
      certifications = data.fetch("certifications")
      raise InvalidCertification, "certification areas are incomplete" unless REQUIRED.all? { |id| certifications[id] == "passed" }
      thresholds = data.fetch("thresholds")
      raise InvalidCertification, "release-blocking threshold breached" unless ZERO_THRESHOLDS.all? { |id| thresholds[id] == 0 }
      findings = Array(data["findings"])
      raise InvalidCertification, "adversarial paths require governed findings" if findings.empty?
      raise InvalidCertification, "unresolved release blocker" if findings.any? { |finding| %w[critical high].include?(finding["severity"]) && finding["status"] != "resolved" }
      evidence = data.fetch("evidence")
      raise InvalidCertification, "evidence must be credential-free" unless evidence["credential_free"] == true && evidence["personal_data"] == false
      raise InvalidCertification, "certification cannot publish" unless data.dig("publication", "allowed") == false

      {
        "schema_version" => 1, "phase" => 6, "status" => "passed",
        "source_commit" => source_commit,
        "certifications" => REQUIRED.map { |id| { "id" => id, "status" => certifications.fetch(id) } },
        "thresholds" => thresholds, "findings" => findings,
        "credential_free" => true, "publication" => { "allowed" => false }
      }
    rescue KeyError, Psych::Exception, Errno::ENOENT => error
      raise InvalidCertification, error.message
    end

    private

    attr_reader :source_commit, :path
  end
end

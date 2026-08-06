# frozen_string_literal: true

module Upgrades
  class BackupEvidenceVerifier
    DEFAULT_MAX_AGE = 24.hours

    def initialize(installed_state:, evidence:, clock: -> { Time.current.utc }, max_age: DEFAULT_MAX_AGE)
      @installed_state = installed_state
      @evidence = evidence
      @clock = clock
      @max_age = max_age
    end

    def verify
      findings = []
      BackupEvidence::KINDS.each do |kind|
        record = evidence.find { |item| item.kind == kind }
        if record.nil?
          findings << finding("backup_evidence_missing", "#{kind} backup evidence is required", kind:)
          next
        end
        findings << finding("backup_evidence_stale", "#{kind} backup evidence is too old", kind:) if clock.call - record.captured_at > max_age
        findings << finding("backup_source_mismatch", "#{kind} backup does not match installed source state", kind:) unless source_matches?(record)
      end
      findings
    end

    private

    attr_reader :installed_state, :evidence, :clock, :max_age

    def source_matches?(record)
      record.source == {
        "platform_version" => installed_state.dig("platform", "version"),
        "database_schema" => installed_state.dig("database", "schema_version"),
        "installation_contract" => installed_state.dig("installation", "contract_version")
      }
    end

    def finding(code, message, details)
      { code:, message:, details: }
    end
  end
end

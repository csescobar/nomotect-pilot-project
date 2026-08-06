# frozen_string_literal: true

module Upgrades
  class PostUpgradeVerifier
    def initialize(manifest:, execution_state:, detector: InstalledStateDetector.new,
      artifact_regenerator: -> { DesignTokens::Compiler.new.write! },
      health_check: -> { ActiveRecord::Base.connection.select_value("SELECT 1").to_s == "1" },
      history: HistoryStore.new, backup_evidence: [], clock: -> { Time.current.utc })
      @manifest = manifest
      @execution_state = execution_state
      @detector = detector
      @artifact_regenerator = artifact_regenerator
      @health_check = health_check
      @history = history
      @backup_evidence = backup_evidence
      @clock = clock
    end

    def verify_and_record!
      digest = ManifestDigest.call(manifest)
      raise HistoryStore::ReplayDetected, "completed upgrade manifest has already been recorded" if history.completed_digest?(digest)

      validate_execution!
      artifact_regenerator.call
      installed = detector.call
      findings = verify(installed)
      raise VerificationFailed, findings unless findings.empty?

      history.append!(history_record(digest, installed))
    end

    private

    attr_reader :manifest, :execution_state, :detector, :artifact_regenerator,
      :health_check, :history, :backup_evidence, :clock

    def validate_execution!
      valid = execution_state["status"] == "completed" &&
        execution_state["manifest_id"] == manifest.id &&
        execution_state["target_version"] == manifest.target_version.to_s
      raise VerificationFailed, [ finding("execution_incomplete", "Matching execution must be completed") ] unless valid
    end

    def verify(installed)
      findings = []
      unless installed.dig("platform", "version") == manifest.target_version.to_s
        findings << finding("target_version_mismatch", "Installed platform version does not match target")
      end
      findings << finding("database_unavailable", "Database verification failed") unless installed.dig("database", "available")
      if Array(installed.dig("database", "pending_migrations")).any?
        findings << finding("database_schema_unverified", "Database still has pending migrations")
      end
      findings << finding("installation_invalid", "Installation state is not completed") unless installed.dig("installation", "state") == "completed"
      findings << finding("generated_artifacts_invalid", "Generated artifacts are not current") unless installed.dig("generated_artifacts", "current")
      findings.concat(contract_findings(installed))
      findings << finding("application_unhealthy", "Application health check failed") unless health_check.call
      findings
    rescue StandardError => error
      [ finding("verification_error", "Post-upgrade verification could not complete", error: error.class.name) ]
    end

    def contract_findings(installed)
      manifest.data.dig("compatibility", "contracts").filter_map do |name, expected|
        actual = installed.dig("contracts", name)
        finding("contract_mismatch", "Installed contract does not match target", contract: name, expected:, actual:) unless actual == expected
      end
    end

    def history_record(digest, installed)
      {
        "schema_version" => HistoryStore::SCHEMA_VERSION,
        "upgrade_id" => manifest.id,
        "manifest_digest" => digest,
        "source_version" => execution_state.fetch("source_version"),
        "target_version" => execution_state.fetch("target_version"),
        "status" => "completed",
        "started_at" => execution_state.fetch("started_at"),
        "completed_at" => clock.call.iso8601,
        "operations" => execution_state.fetch("operations").map { |item| item.slice("id", "status") },
        "evidence" => {
          "database_schema" => installed.dig("database", "schema_version"),
          "installation_contract" => installed.dig("installation", "contract_version"),
          "generated_artifacts_current" => true,
          "application_healthy" => true,
          "backup_evidence_ids" => backup_evidence.map { |item| item.data.fetch("id") }
        }
      }
    end

    def finding(code, message, details = {})
      { code:, message:, details: }
    end

    class VerificationFailed < StandardError
      attr_reader :findings

      def initialize(findings)
        @findings = findings
        super("post-upgrade verification failed")
      end
    end
  end
end

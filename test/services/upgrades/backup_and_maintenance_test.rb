# frozen_string_literal: true

require "test_helper"

module Upgrades
  class BackupAndMaintenanceTest < ActiveSupport::TestCase
    test "accepts current evidence matching installed source" do
      records = %w[database persistent_files].map { |kind| evidence(kind) }
      findings = BackupEvidenceVerifier.new(
        installed_state: installed_state,
        evidence: records,
        clock: -> { Time.iso8601("2026-07-27T22:00:00Z") }
      ).verify

      assert_empty findings
    end

    test "rejects missing stale and source-mismatched evidence" do
      stale = evidence("database", captured_at: "2026-07-25T20:00:00Z", database_schema: "1")

      findings = BackupEvidenceVerifier.new(
        installed_state: installed_state,
        evidence: [ stale ],
        clock: -> { Time.iso8601("2026-07-27T22:00:00Z") }
      ).verify

      assert_includes findings.pluck(:code), "backup_evidence_stale"
      assert_includes findings.pluck(:code), "backup_source_mismatch"
      assert_includes findings.pluck(:code), "backup_evidence_missing"
    end

    test "maintenance control persists explicit activation" do
      Dir.mktmpdir do |directory|
        control = MaintenanceControl.new(path: File.join(directory, "maintenance.json"))
        assert_not control.active?
        assert control.activate!.fetch("active")
        assert control.active?
        assert_not control.deactivate!.fetch("active")
      end
    end

    test "execution gate fails closed on evidence maintenance requests and jobs" do
      report = Data.define(:blockers).new([])
      maintenance = Object.new
      maintenance.define_singleton_method(:active?) { false }
      gate = ExecutionSafetyGate.new(
        preflight_report: report,
        evidence_findings: [ { code: "backup_evidence_missing" } ],
        maintenance: maintenance,
        active_requests: 1,
        active_jobs: 2
      )

      assert_not gate.ready?
      codes = gate.findings.pluck(:code)
      assert_includes codes, "maintenance_mode_required"
      assert_includes codes, "active_requests_present"
      assert_includes codes, "active_jobs_present"
      assert_raises(ExecutionSafetyGate::UnsafeExecution) { gate.authorize! }
    end

    private

    def installed_state
      {
        "platform" => { "version" => "0.4.0" },
        "database" => { "schema_version" => "20260727180000" },
        "installation" => { "contract_version" => 1 }
      }
    end

    def evidence(kind, captured_at: "2026-07-27T20:00:00Z", database_schema: "20260727180000")
      BackupEvidence.new(
        "schema_version" => 1,
        "id" => "#{kind}-1",
        "kind" => kind,
        "captured_at" => captured_at,
        "source" => {
          "platform_version" => "0.4.0",
          "database_schema" => database_schema,
          "installation_contract" => 1
        },
        "provider" => "operator",
        "reference" => "backup-reference",
        "checksum" => nil
      )
    end
  end
end

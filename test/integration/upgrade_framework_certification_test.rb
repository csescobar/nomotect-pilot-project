# frozen_string_literal: true

require "test_helper"

class UpgradeFrameworkCertificationTest < ActiveSupport::TestCase
  test "certifies interruption resume verification history and replay protection" do
    Dir.mktmpdir do |directory|
      manifest = target_manifest
      detector = fake(call: source_state)
      report = Upgrades::Inspector.new(manifest: manifest, detector: detector).preflight
      evidence = backup_evidence
      evidence_findings = Upgrades::BackupEvidenceVerifier.new(
        installed_state: source_state,
        evidence: evidence,
        clock: -> { certification_time }
      ).verify
      gate = Upgrades::ExecutionSafetyGate.new(
        preflight_report: report,
        evidence_findings: evidence_findings,
        maintenance: fake(active?: true)
      )
      store = Upgrades::ExecutionStore.new(path: File.join(directory, "execution.json"))
      lock = Installation::ExecutionLock.new(path: File.join(directory, "execution.lock"))
      calls = []
      stop_once = true
      registry = Upgrades::OperationRegistry.new
      registry.register("configure") { calls << "configure" }
      registry.register("migrate") do
        throw :simulated_interruption if stop_once

        calls << "migrate"
      end
      executor = Upgrades::Executor.new(
        plan: report.plan,
        safety_gate: gate,
        registry: registry,
        store: store,
        lock: lock,
        clock: -> { certification_time }
      )

      catch(:simulated_interruption) { executor.execute! }
      assert_equal "running", store.read.fetch("status")
      guidance = Upgrades::RecoveryAdvisor.new(
        manifest: manifest,
        execution_state: store.read
      ).call
      assert_equal "retryable", guidance.fetch("classification")

      stop_once = false
      executor.execute!
      assert_equal %w[configure migrate], calls
      assert_equal "completed", store.read.fetch("status")

      history = Upgrades::HistoryStore.new(path: File.join(directory, "history.json"))
      verifier = Upgrades::PostUpgradeVerifier.new(
        manifest: manifest,
        execution_state: store.read,
        detector: fake(call: target_state),
        artifact_regenerator: -> { true },
        health_check: -> { true },
        history: history,
        backup_evidence: evidence,
        clock: -> { certification_time }
      )
      record = verifier.verify_and_record!

      assert_equal "completed", record.fetch("status")
      assert_equal %w[database-1 persistent_files-1], record.dig("evidence", "backup_evidence_ids")
      assert_raises(Upgrades::HistoryStore::ReplayDetected) { verifier.verify_and_record! }
    end
  end

  test "certification rejects incompatible source and stale backup" do
    incompatible = Upgrades::Inspector.new(
      manifest: target_manifest,
      detector: fake(call: source_state.merge("platform" => { "version" => "0.3.0" }))
    ).preflight
    assert_includes incompatible.blockers.pluck(:code), "compatibility_failed"

    stale_evidence = backup_evidence(captured_at: "2026-07-25T00:00:00Z")
    findings = Upgrades::BackupEvidenceVerifier.new(
      installed_state: source_state,
      evidence: stale_evidence,
      clock: -> { certification_time }
    ).verify
    assert_equal 2, findings.count { |finding| finding.fetch(:code) == "backup_evidence_stale" }
  end

  private

  def fake(**methods)
    Object.new.tap do |object|
      methods.each do |name, value|
        object.define_singleton_method(name) { value }
      end
    end
  end

  def certification_time
    Time.iso8601("2026-07-28T00:00:00Z")
  end

  def backup_evidence(captured_at: "2026-07-27T23:00:00Z")
    %w[database persistent_files].map do |kind|
      Upgrades::BackupEvidence.new(
        "schema_version" => 1,
        "id" => "#{kind}-1",
        "kind" => kind,
        "captured_at" => captured_at,
        "source" => {
          "platform_version" => "0.4.0",
          "database_schema" => "20260727000000",
          "installation_contract" => 1
        },
        "provider" => "certification",
        "reference" => "#{kind}-reference",
        "checksum" => nil
      )
    end
  end

  def source_state
    {
      "schema_version" => 1,
      "observed_at" => "2026-07-27T23:00:00Z",
      "environment" => "production",
      "platform" => { "version" => "0.4.0" },
      "runtime" => {
        "ruby" => "4.0.5",
        "rails" => "8.1.3",
        "postgresql" => "18.4.0"
      },
      "contracts" => {
        "installation-state" => 1,
        "upgrade-history" => 1
      },
      "installation" => { "contract_version" => 1, "state" => "completed" },
      "deployment" => { "contract_version" => nil, "profile" => "certification" },
      "database" => {
        "available" => true,
        "schema_version" => "20260727000000",
        "pending_migrations" => []
      },
      "generated_artifacts" => { "current" => true, "checks" => [ "design_tokens" ] },
      "extensions" => []
    }
  end

  def target_state
    source_state.deep_merge(
      "platform" => { "version" => "0.5.0" },
      "database" => { "schema_version" => "20260728000000" }
    )
  end

  def target_manifest
    @target_manifest ||= Upgrades::Manifest.new(
      "schema_version" => 1,
      "id" => "upgrade-certification",
      "source" => { "requirement" => ">= 0.4.0, < 0.5.0" },
      "target" => { "version" => "0.5.0" },
      "compatibility" => {
        "rails" => "~> 8.1.0",
        "ruby" => "~> 4.0.0",
        "postgresql" => "~> 18.0",
        "contracts" => { "installation-state" => 1, "upgrade-history" => 1 }
      },
      "backup" => { "required" => true, "evidence" => %w[database persistent_files] },
      "operations" => [
        {
          "id" => "configure",
          "type" => "configuration",
          "description" => "Configure",
          "reversible" => true,
          "requires" => []
        },
        {
          "id" => "migrate",
          "type" => "database",
          "description" => "Migrate",
          "reversible" => false,
          "requires" => [ "configure" ]
        }
      ],
      "deprecations" => []
    )
  end
end

# frozen_string_literal: true

require "test_helper"
require "digest"
require "fileutils"
require "tmpdir"

class OperationalRestoreCertificationTest < ActiveSupport::TestCase
  setup do
    @root = Pathname(Dir.mktmpdir("operational-restore-certification-", Rails.root.join("tmp")))
    @backup_root = @root.join("backup")
    @target_root = @root.join("restored")
    @backup_root.mkpath
    write_backup_components
  end

  teardown { FileUtils.rm_rf(@root) }

  test "certifies a complete production-like restore" do
    execution = executor.execute!
    evidence = verifier(execution:).verify!

    assert_equal "completed", execution.fetch("status")
    assert_equal OperationalReadiness::BackupManifest::COMPONENT_KINDS, execution.fetch("steps").pluck("component")
    assert_equal "certified", evidence.fetch("status")
    assert evidence.fetch("checks").values.all?
    OperationalReadiness::BackupManifest::COMPONENT_KINDS.each do |kind|
      assert_equal component_content(kind), @target_root.join("#{kind}.data").read
    end
  end

  test "fails closed without confirmation or valid component checksum" do
    unconfirmed_gate = safety_gate(confirmed_step_ids: [])
    error = assert_raises(OperationalReadiness::RestoreSafetyGate::UnsafeRestore) do
      executor(safety_gate: unconfirmed_gate).execute!
    end
    assert_includes error.findings.pluck(:code), "operator_confirmation_required"

    @backup_root.join("postgresql.data").write("tampered")
    assert_raises(OperationalReadiness::RestoreExecutor::ChecksumMismatch) { executor.execute! }
    refute @target_root.exist?
  end

  private

  def executor(safety_gate: self.safety_gate)
    OperationalReadiness::RestoreExecutor.new(
      manifest:,
      plan:,
      safety_gate:,
      registry:,
      checksum_verifier: method(:checksum_valid?),
      lock: Installation::ExecutionLock.new(path: @root.join("restore.lock")),
      clock: -> { certification_time }
    )
  end

  def verifier(execution:)
    OperationalReadiness::RestoreVerifier.new(
      manifest:,
      plan:,
      execution:,
      checks: {
        "database_schema" => -> { restored?("postgresql") },
        "installation_contract" => -> { restored?("installation_metadata") },
        "generated_artifacts" => -> { restored?("generated_configuration") },
        "application_health" => -> { restored?("persistent_files") }
      },
      clock: -> { certification_time }
    )
  end

  def safety_gate(confirmed_step_ids: plan.ordered_steps.pluck("id"))
    OperationalReadiness::RestoreSafetyGate.new(
      manifest:,
      plan:,
      maintenance: Object.new.tap { |value| value.define_singleton_method(:active?) { true } },
      confirmed_step_ids:
    )
  end

  def registry
    @registry ||= OperationalReadiness::RestoreAdapterRegistry.new.tap do |value|
      OperationalReadiness::BackupManifest::COMPONENT_KINDS.each do |kind|
        value.register("certification", kind) do |component:, **|
          @target_root.mkpath
          source = Pathname(component.fetch("reference").delete_prefix("file://"))
          FileUtils.cp(source, @target_root.join("#{kind}.data"))
        end
      end
    end
  end

  def checksum_valid?(component)
    source = Pathname(component.fetch("reference").delete_prefix("file://"))
    component.fetch("checksum") == "sha256:#{Digest::SHA256.file(source).hexdigest}"
  end

  def restored?(kind)
    path = @target_root.join("#{kind}.data")
    path.file? && path.read == component_content(kind)
  end

  def manifest
    @manifest ||= OperationalReadiness::BackupManifest.new(
      "schema_version" => 1,
      "id" => "backup-certification",
      "captured_at" => certification_time.iso8601,
      "source" => {
        "platform_version" => "0.9.0",
        "source_commit" => "9" * 40,
        "database_schema" => "20260730000000",
        "installation_contract" => 1
      },
      "components" => OperationalReadiness::BackupManifest::COMPONENT_KINDS.map do |kind|
        path = @backup_root.join("#{kind}.data")
        {
          "id" => "#{kind}-certification",
          "kind" => kind,
          "provider" => "certification",
          "reference" => "file://#{path}",
          "checksum" => "sha256:#{Digest::SHA256.file(path).hexdigest}",
          "size_bytes" => path.size
        }
      end
    )
  end

  def plan
    @plan ||= OperationalReadiness::RestorePlan.new(
      "schema_version" => 1,
      "id" => "restore-certification",
      "backup_manifest_id" => "backup-certification",
      "target" => {
        "environment" => "production-like",
        "platform_version" => "0.9.0"
      },
      "ordered_steps" => OperationalReadiness::BackupManifest::COMPONENT_KINDS.map.with_index do |kind, index|
        {
          "id" => "restore-#{kind}",
          "component" => kind,
          "action" => "restore through the certification adapter",
          "requires" => index.zero? ? [] : [ "restore-#{OperationalReadiness::BackupManifest::COMPONENT_KINDS[index - 1]}" ],
          "operator_confirmation" => true
        }
      end,
      "verification" => OperationalReadiness::RestoreVerifier::CHECKS.index_with(true)
    )
  end

  def write_backup_components
    OperationalReadiness::BackupManifest::COMPONENT_KINDS.each do |kind|
      @backup_root.join("#{kind}.data").write(component_content(kind))
    end
  end

  def component_content(kind)
    "certified #{kind}\n"
  end

  def certification_time
    Time.iso8601("2026-07-30T23:30:00Z")
  end
end

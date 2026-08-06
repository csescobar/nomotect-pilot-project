# frozen_string_literal: true

require "test_helper"

class OperationalExamplesCertificationTest < ActiveSupport::TestCase
  ROOT = Rails.root.join("docs/examples")

  test "loads the extension example through the production manifest parser" do
    manifest = Extensions::Manifest.load(ROOT.join("extension-manifest.yml"))

    assert_equal "example.audit-reports", manifest.id
    assert_equal [ "audit.reports" ], manifest.provided_capabilities.pluck("id")
  end

  test "loads the upgrade example through the production manifest parser" do
    manifest = Upgrades::Manifest.load(ROOT.join("upgrade-manifest.json"))

    assert_equal "example-upgrade-0-9-1", manifest.id
    assert manifest.backup_required?
    assert_equal %w[verify-backup migrate-database verify-platform], manifest.operations.pluck("id")
  end

  test "loads the complete credential-free backup example" do
    manifest = OperationalReadiness::BackupManifest.load(ROOT.join("backup-manifest.json"))

    assert_equal OperationalReadiness::BackupManifest::COMPONENT_KINDS, manifest.components.pluck("kind")
    assert_equal "0.9.0", manifest.source.fetch("platform_version")
  end

  test "keeps the example catalog complete and free of credential fields" do
    examples = %w[extension-manifest.yml upgrade-manifest.json backup-manifest.json]

    examples.each do |name|
      contents = ROOT.join(name).read

      assert_includes ROOT.join("README.md").read, name
      refute_match(/password|credential|token|private_key/i, contents)
    end
  end
end

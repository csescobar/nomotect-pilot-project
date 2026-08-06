# frozen_string_literal: true

require "test_helper"

module OperationalReadiness
  class BackupManifestTest < ActiveSupport::TestCase
    test "accepts a complete credential-free backup set" do
      manifest = BackupManifest.new(valid_manifest)

      assert_equal "backup-20260730", manifest.id
      assert_equal BackupManifest::COMPONENT_KINDS, manifest.components.pluck("kind")
      assert manifest.data.frozen?
    end

    test "rejects incomplete duplicate and secret-bearing manifests" do
      incomplete = valid_manifest
      incomplete["components"].pop
      assert_raises(BackupManifest::InvalidManifest) { BackupManifest.new(incomplete) }

      duplicate = valid_manifest
      duplicate["components"][1]["kind"] = "postgresql"
      assert_raises(BackupManifest::InvalidManifest) { BackupManifest.new(duplicate) }

      secret_bearing = valid_manifest
      secret_bearing["source"]["password"] = "not-allowed"
      assert_raises(BackupManifest::InvalidManifest) { BackupManifest.new(secret_bearing) }
    end

    private

    def valid_manifest
      {
        "schema_version" => 1,
        "id" => "backup-20260730",
        "captured_at" => "2026-07-30T23:00:00Z",
        "source" => {
          "platform_version" => "0.9.0",
          "source_commit" => "0" * 40,
          "database_schema" => "20260730180000",
          "installation_contract" => 1
        },
        "components" => BackupManifest::COMPONENT_KINDS.map.with_index do |kind, index|
          {
            "id" => "#{kind}-#{index}",
            "kind" => kind,
            "provider" => "operator",
            "reference" => "backup://#{kind}",
            "checksum" => "sha256:#{"a" * 64}",
            "size_bytes" => index
          }
        end
      }
    end
  end
end

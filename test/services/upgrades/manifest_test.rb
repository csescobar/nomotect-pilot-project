# frozen_string_literal: true

require "test_helper"

module Upgrades
  class ManifestTest < ActiveSupport::TestCase
    test "accepts a strict versioned manifest" do
      manifest = Manifest.new(manifest_data)

      assert_equal "upgrade-1-1", manifest.id
      assert_equal ">= 1.0.0, < 1.1.0", manifest.source_requirement
      assert_equal "1.1.0", manifest.target_version.to_s
      assert manifest.backup_required?
      assert_equal %w[verify-backup migrate validate], manifest.operations.pluck("id")
    end

    test "rejects unknown properties" do
      data = manifest_data.merge("unexpected" => true)

      error = assert_raises(Manifest::InvalidManifest) { Manifest.new(data) }
      assert_includes error.message, "unsupported keys"
    end

    test "rejects duplicate operation ids" do
      data = manifest_data
      data["operations"][1]["id"] = data["operations"][0]["id"]

      error = assert_raises(Manifest::InvalidManifest) { Manifest.new(data) }
      assert_includes error.message, "must be unique"
    end

    private

    def manifest_data
      {
        "schema_version" => 1,
        "id" => "upgrade-1-1",
        "source" => { "requirement" => ">= 1.0.0, < 1.1.0" },
        "target" => { "version" => "1.1.0" },
        "compatibility" => {
          "rails" => "~> 8.1.0",
          "ruby" => "~> 4.0.0",
          "postgresql" => ">= 16.0.0, < 19.0.0",
          "contracts" => { "installation-state" => 1, "upgrade-history" => 1 }
        },
        "backup" => { "required" => true, "evidence" => [ "database_backup_id" ] },
        "operations" => [
          { "id" => "verify-backup", "type" => "validation", "description" => "Verify backup evidence", "reversible" => true, "requires" => [] },
          { "id" => "migrate", "type" => "database", "description" => "Run database migrations", "reversible" => false, "requires" => [ "verify-backup" ] },
          { "id" => "validate", "type" => "validation", "description" => "Validate the upgraded application", "reversible" => true, "requires" => [ "migrate" ] }
        ],
        "deprecations" => []
      }
    end
  end
end

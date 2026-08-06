# frozen_string_literal: true

require "test_helper"

module Upgrades
  class PlannerTest < ActiveSupport::TestCase
    test "produces a deterministic compatible plan" do
      plan = Planner.new(
        manifest: Manifest.new(manifest_data),
        current_version: "1.0.4",
        runtime: {
          ruby: "4.0.5",
          rails: "8.1.3",
          postgresql: "18.0.0",
          contracts: { "installation-state" => 1, "upgrade-history" => 1 }
        }
      ).plan

      assert_equal "upgrade-1-1", plan.manifest_id
      assert_equal "1.0.4", plan.source_version
      assert_equal "1.1.0", plan.target_version
      assert plan.backup_required
      assert_equal %w[verify-backup migrate validate], plan.operations.pluck("id")
    end

    test "rejects an incompatible installed version" do
      error = assert_raises(Planner::IncompatibleUpgrade) do
        Planner.new(manifest: Manifest.new(manifest_data), current_version: "0.9.9").plan
      end

      assert_includes error.message, "does not satisfy"
    end

    test "rejects incompatible runtime contracts" do
      error = assert_raises(Planner::IncompatibleUpgrade) do
        Planner.new(
          manifest: Manifest.new(manifest_data),
          current_version: "1.0.4",
          runtime: { contracts: { "installation-state" => 2 } }
        ).plan
      end

      assert_includes error.message, "does not match required version"
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

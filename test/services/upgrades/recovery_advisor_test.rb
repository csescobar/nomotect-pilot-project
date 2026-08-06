# frozen_string_literal: true

require "test_helper"

module Upgrades
  class RecoveryAdvisorTest < ActiveSupport::TestCase
    test "classifies interrupted execution as retryable" do
      guidance = RecoveryAdvisor.new(
        manifest: manifest,
        execution_state: execution_state("running")
      ).call

      assert_equal "retryable", guidance.fetch("classification")
      assert_equal "execution_interrupted", guidance.fetch("failure_code")
      assert_not guidance.dig("rollback", "automatic")
    end

    test "requires forward recovery after irreversible operation failure" do
      state = execution_state("failed")
      state["operations"] = [
        { "id" => "configure", "status" => "completed" },
        { "id" => "migrate", "status" => "failed" }
      ]

      guidance = RecoveryAdvisor.new(manifest: manifest, execution_state: state).call

      assert_equal "forward_recovery", guidance.fetch("classification")
      assert_equal "irreversible_operation_failed", guidance.fetch("failure_code")
      assert_equal "migrate", guidance.fetch("failed_operation_id")
    end

    test "requires operator intervention for stale backup evidence" do
      guidance = RecoveryAdvisor.new(
        manifest: manifest,
        findings: [ { code: "backup_evidence_stale" } ]
      ).call

      assert_equal "operator_intervention", guidance.fetch("classification")
      assert_equal "backup_evidence_invalid", guidance.fetch("failure_code")
      assert_equal 3, guidance.fetch("actions").size
    end

    test "matches the strict recovery contract keys" do
      schema = JSON.parse(Rails.root.join("docs/contracts/upgrade-recovery.schema.json").read)
      guidance = RecoveryAdvisor.new(
        manifest: manifest,
        execution_state: execution_state("running")
      ).call

      assert_not schema.fetch("additionalProperties")
      assert_equal schema.fetch("required").sort, guidance.keys.sort
      assert_includes schema.dig("properties", "classification", "enum"), guidance.fetch("classification")
    end

    private

    def execution_state(status)
      {
        "manifest_id" => manifest.id,
        "status" => status,
        "operations" => []
      }
    end

    def manifest
      @manifest ||= Manifest.new(
        "schema_version" => 1,
        "id" => "upgrade-recovery",
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
end

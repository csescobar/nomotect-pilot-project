# frozen_string_literal: true

require "test_helper"

module OperationalReadiness
  class RestorePlanTest < ActiveSupport::TestCase
    test "accepts explicit ordered restore dependencies" do
      plan = RestorePlan.new(valid_plan)

      assert_equal "backup-20260730", plan.backup_manifest_id
      assert_equal %w[restore-database restore-files], plan.ordered_steps.pluck("id")
      assert plan.data.frozen?
    end

    test "rejects forward dependencies and secret-bearing plans" do
      forward_dependency = valid_plan
      forward_dependency["ordered_steps"][0]["requires"] = [ "restore-files" ]
      assert_raises(RestorePlan::InvalidPlan) { RestorePlan.new(forward_dependency) }

      secret_bearing = valid_plan
      secret_bearing["target"]["token"] = "not-allowed"
      assert_raises(RestorePlan::InvalidPlan) { RestorePlan.new(secret_bearing) }
    end

    private

    def valid_plan
      {
        "schema_version" => 1,
        "id" => "restore-20260730",
        "backup_manifest_id" => "backup-20260730",
        "target" => {
          "environment" => "production-like",
          "platform_version" => "0.9.0"
        },
        "ordered_steps" => [
          {
            "id" => "restore-database",
            "component" => "postgresql",
            "action" => "restore PostgreSQL through an approved provider adapter",
            "requires" => [],
            "operator_confirmation" => true
          },
          {
            "id" => "restore-files",
            "component" => "persistent_files",
            "action" => "restore persistent files through an approved provider adapter",
            "requires" => [ "restore-database" ],
            "operator_confirmation" => true
          }
        ],
        "verification" => {
          "database_schema" => true,
          "installation_contract" => true,
          "generated_artifacts" => true,
          "application_health" => true
        }
      }
    end
  end
end

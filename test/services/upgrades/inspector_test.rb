# frozen_string_literal: true

require "test_helper"

module Upgrades
  class InspectorTest < ActiveSupport::TestCase
    test "produces a ready read-only preflight plan" do
      report = Inspector.new(manifest: manifest(backup_required: false), detector: fake(call: installed_state)).preflight

      assert report.ready?
      assert_equal "ready", report.status
      assert_equal "0.5.0", report.plan.target_version
      assert_empty report.blockers
      assert_empty report.operator_actions
    end

    test "reports blockers with stable failure codes" do
      state = installed_state
      state["platform"]["version"] = nil
      state["installation"]["state"] = "migrations"
      state["database"]["pending_migrations"] = [ { "version" => "20260727190000", "name" => "Pending" } ]
      state["contracts"].delete("installation-state")

      report = Inspector.new(manifest: manifest(backup_required: false), detector: fake(call: state)).preflight
      codes = report.blockers.pluck(:code)

      assert_not report.ready?
      assert_equal "blocked", report.status
      assert_includes codes, "source_version_unavailable"
      assert_includes codes, "installation_incomplete"
      assert_includes codes, "pending_source_migrations"
      assert_includes codes, "contract_state_unavailable"
      assert_nil report.plan
    end

    test "returns warnings and operator actions without blocking readiness" do
      state = installed_state
      state["generated_artifacts"]["current"] = false

      report = Inspector.new(
        manifest: manifest(operator_action: true, deprecation: true, backup_required: true),
        detector: fake(call: state)
      ).preflight

      assert report.ready?
      assert_equal "warnings", report.status
      assert_equal "generated_artifacts_stale", report.warnings.first.fetch(:code)
      assert_equal %w[backup_evidence_required operator_action_required], report.operator_actions.pluck(:code)
    end

    test "inspect reports observations without creating an execution plan" do
      report = Inspector.new(manifest: manifest(backup_required: false), detector: fake(call: installed_state)).inspect

      assert_equal "inspect", report.mode
      assert_nil report.plan
      assert report.ready?
    end

    test "blocks for incompatible extension state and pending extension migrations" do
      state = installed_state
      state["extensions"] = [
        {
          "id" => "acme.audit",
          "status" => "blocked",
          "finding_codes" => [ "extension_contract_incompatible" ],
          "pending_migrations" => [
            {
              "namespace" => "acme.audit",
              "version" => "20260728100000",
              "name" => "Add audit event source"
            }
          ]
        }
      ]

      report = Inspector.new(
        manifest: manifest(backup_required: false),
        detector: fake(call: state)
      ).preflight

      assert_equal "blocked", report.status
      assert_includes report.blockers.pluck(:code), "extension_state_incompatible"
      assert_includes report.blockers.pluck(:code), "pending_extension_migrations"
      assert_nil report.plan
    end

    private

    def fake(**methods)
      Object.new.tap do |object|
        methods.each { |name, value| object.define_singleton_method(name) { value } }
      end
    end

    def installed_state
      {
        "schema_version" => 1,
        "observed_at" => "2026-07-27T22:00:00Z",
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
        "deployment" => { "contract_version" => nil, "profile" => nil },
        "database" => {
          "available" => true,
          "schema_version" => "20260727180000",
          "pending_migrations" => []
        },
        "generated_artifacts" => { "current" => true, "checks" => [ "design_tokens" ] },
        "extensions" => []
      }
    end

    def manifest(operator_action: false, deprecation: false, backup_required: false)
      operations = [
        {
          "id" => "migrate",
          "type" => "database",
          "description" => "Run database migrations",
          "reversible" => false,
          "requires" => []
        }
      ]
      if operator_action
        operations.unshift(
          {
            "id" => "maintenance",
            "type" => "operator_action",
            "description" => "Enable maintenance mode",
            "reversible" => true,
            "requires" => []
          }
        )
      end

      Manifest.new(
        "schema_version" => 1,
        "id" => "upgrade-0-5",
        "source" => { "requirement" => ">= 0.4.0, < 0.5.0" },
        "target" => { "version" => "0.5.0" },
        "compatibility" => {
          "rails" => "~> 8.1.0",
          "ruby" => "~> 4.0.0",
          "postgresql" => ">= 18.0.0, < 19.0.0",
          "contracts" => { "installation-state" => 1, "upgrade-history" => 1 }
        },
        "backup" => {
          "required" => backup_required,
          "evidence" => backup_required ? [ "database_backup_id" ] : []
        },
        "operations" => operations,
        "deprecations" => deprecation ? [
          {
            "contract" => "legacy-branding",
            "remove_in" => "0.6.0",
            "replacement" => "appearance-v2"
          }
        ] : []
      )
    end
  end
end

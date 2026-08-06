# frozen_string_literal: true

require "test_helper"

module Extensions
  class CompatibilityPlannerTest < ActiveSupport::TestCase
    test "builds a deterministic dependency-first load order" do
      reporting = package("acme.reporting", provides: [ capability("reporting.api", 2) ])
      audit = package(
        "acme.audit",
        dependencies: [ dependency("acme.reporting", ">= 2.0") ],
        requires: [ requirement("reporting.api", ">= 2, < 3") ]
      )

      result = plan(audit, reporting)

      assert_empty result.blockers
      assert_equal %w[acme.reporting acme.audit], result.plan.load_order
    end

    test "blocks an incompatible platform version" do
      result = plan(package("acme.audit", platform: ">= 1.0.0"))

      assert_equal [ "platform_version_incompatible" ], result.blockers.pluck(:code)
      assert_empty result.plan.load_order
    end

    test "blocks an unsupported extension contract version" do
      result = plan(package("acme.audit", contract_version: 2))

      assert_equal [ "extension_contract_incompatible" ], result.blockers.pluck(:code)
    end

    test "blocks a missing extension dependency" do
      audit = package(
        "acme.audit",
        dependencies: [ dependency("acme.reporting", "~> 2.0") ]
      )

      result = plan(audit)

      assert_equal [ "extension_dependency_missing" ], result.blockers.pluck(:code)
    end

    test "blocks an incompatible extension dependency version" do
      reporting = package("acme.reporting", version: "2.1.0")
      audit = package(
        "acme.audit",
        dependencies: [ dependency("acme.reporting", ">= 3.0") ]
      )

      result = plan(audit, reporting)

      assert_equal [ "extension_dependency_incompatible" ], result.blockers.pluck(:code)
    end

    test "blocks a dependency cycle" do
      audit = package("acme.audit", dependencies: [ dependency("acme.reporting", ">= 1") ])
      reporting = package("acme.reporting", dependencies: [ dependency("acme.audit", ">= 1") ])

      result = plan(audit, reporting)

      assert_includes result.blockers.pluck(:code), "extension_dependency_cycle"
    end

    test "blocks duplicate capability providers" do
      first = package("acme.audit", provides: [ capability("audit.events", 1) ])
      second = package("acme.reporting", provides: [ capability("audit.events", 1) ])

      result = plan(first, second)

      assert_equal [ "capability_provider_conflict" ], result.blockers.pluck(:code)
    end

    test "accepts a compatible platform capability" do
      audit = package(
        "acme.audit",
        requires: [ requirement("platform.events", ">= 1, < 2") ]
      )

      result = plan(audit, core_capabilities: { "platform.events" => 1 })

      assert_empty result.blockers
      assert_equal [ "acme.audit" ], result.plan.load_order
    end

    test "blocks a missing capability" do
      audit = package(
        "acme.audit",
        requires: [ requirement("platform.events", ">= 1") ]
      )

      result = plan(audit)

      assert_equal [ "capability_missing" ], result.blockers.pluck(:code)
    end

    test "blocks an incompatible capability version" do
      audit = package(
        "acme.audit",
        requires: [ requirement("platform.events", ">= 2") ]
      )

      result = plan(audit, core_capabilities: { "platform.events" => 1 })

      assert_equal [ "capability_version_incompatible" ], result.blockers.pluck(:code)
    end

    private

    def plan(*packages, core_capabilities: {})
      CompatibilityPlanner.new(
        packages:,
        platform_version: "0.9.0",
        core_capabilities:
      ).call
    end

    def package(
      id,
      version: "2.1.0",
      platform: ">= 0.9.0, < 1.0.0",
      contract_version: 1,
      dependencies: [],
      provides: [],
      requires: []
    )
      manifest = Manifest.new({
        "schema_version" => 1,
        "extension" => {
          "id" => id,
          "version" => version,
          "contract_version" => contract_version,
          "entrypoint" => id.tr(".-", "_")
        },
        "platform" => { "requirement" => platform },
        "capabilities" => { "provides" => provides, "requires" => requires },
        "dependencies" => dependencies,
        "components" => {
          "configuration" => nil,
          "migrations" => { "namespace" => id, "paths" => [] },
          "routes" => { "namespace" => id },
          "assets" => { "namespace" => id },
          "documentation" => nil
        },
        "security" => { "trust" => "trusted_in_process" }
      })
      Package.new(
        declaration: {
          "id" => id,
          "package" => id.tr(".", "-"),
          "enabled" => true,
          "required" => true
        },
        root: Pathname("/tmp").join(id),
        manifest:
      )
    end

    def dependency(id, requirement)
      { "id" => id, "requirement" => requirement }
    end

    def capability(id, version)
      { "id" => id, "version" => version }
    end

    def requirement(id, value)
      { "id" => id, "requirement" => value }
    end
  end
end

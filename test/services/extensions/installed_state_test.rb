# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"
require_relative "../../support/extension_package_helper"

module Extensions
  class InstalledStateTest < ActiveSupport::TestCase
    include ExtensionPackageHelper

    test "reports namespaced components and pending extension migrations" do
      with_package do |configuration, package|
        report = InspectionReport.new(
          mode: :preflight,
          configuration: configuration,
          packages: [ package ],
          plan: CompatibilityPlanner::Plan.new("0.9.0", [ package.id ], [ package.to_h ])
        )
        migration_context = fake(
          migrations_status: [
            [ "up", "20260728090000", "Create audit events" ],
            [ "down", "20260728100000", "Add audit event source" ]
          ]
        )

        state = InstalledState.new(
          report: report,
          migration_context_factory: ->(_paths) { migration_context }
        ).call.fetch(0)

        assert_equal "ready", state.fetch("status")
        assert_equal "acme.audit", state.dig("components", "migrations", "namespace")
        assert_equal 1, state.dig("components", "migrations", "paths")
        assert_equal "20260728100000", state.dig("pending_migrations", 0, "version")
        assert_equal "acme.audit", state.dig("pending_migrations", 0, "namespace")
      end
    end

    test "reports configured packages that discovery could not resolve" do
      configuration = Configuration.new({
        "schema_version" => 1,
        "extensions" => [ extension_declaration("acme.missing") ]
      })
      report = InspectionReport.new(
        mode: :preflight,
        configuration: configuration,
        packages: [],
        blockers: [
          {
            code: "extension_package_missing",
            message: "Configured extension package is not installed",
            details: extension_declaration("acme.missing")
          }
        ]
      )

      state = InstalledState.new(report:).call.fetch(0)

      assert_equal "blocked", state.fetch("status")
      assert_nil state.fetch("version")
      assert_includes state.fetch("finding_codes"), "extension_package_missing"
    end

    test "fails closed when extension migration state is unavailable" do
      with_package do |configuration, package|
        report = InspectionReport.new(
          mode: :preflight,
          configuration: configuration,
          packages: [ package ],
          plan: CompatibilityPlanner::Plan.new("0.9.0", [ package.id ], [ package.to_h ])
        )

        state = InstalledState.new(
          report: report,
          migration_context_factory: ->(_paths) { raise ActiveRecord::ConnectionNotEstablished }
        ).call.fetch(0)

        assert_equal "blocked", state.fetch("status")
        assert_includes state.fetch("finding_codes"), "extension_migration_state_unavailable"
      end
    end

    private

    def with_package
      Dir.mktmpdir("installed-extension") do |directory|
        root = Pathname(directory)
        FileUtils.mkdir_p(root.join("db/migrate"))
        package = extension_package("acme.audit", migration_paths: [ "db/migrate" ])
        package = Package.new(declaration: package.declaration, root:, manifest: package.manifest)
        configuration = Configuration.new({
          "schema_version" => 1,
          "extensions" => [ package.declaration ]
        })
        yield configuration, package
      end
    end

    def fake(**methods)
      Object.new.tap do |object|
        methods.each { |name, value| object.define_singleton_method(name) { value } }
      end
    end
  end
end

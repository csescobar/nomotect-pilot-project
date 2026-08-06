# frozen_string_literal: true

require "test_helper"
require_relative "../../support/extension_package_helper"

module Extensions
  class LoaderTest < ActiveSupport::TestCase
    include ExtensionPackageHelper

    test "loads a ready graph in dependency order and seals the registry" do
      reporting = extension_package(
        "acme.reporting",
        provides: [ provided_capability("reporting.api", 1) ]
      )
      audit = extension_package(
        "acme.audit",
        dependencies: [ extension_dependency("acme.reporting", ">= 1") ],
        requires: [ required_capability("reporting.api", ">= 1") ]
      )
      calls = []
      loader = Loader.new(
        report: ready_report(audit, reporting),
        requireer: registering_requireer([ audit, reporting ], calls)
      )

      first = loader.call
      second = loader.call

      assert_same first, second
      assert_equal %w[acme_reporting acme_audit], calls
      assert_equal %w[acme.reporting acme.audit], first.loaded
      assert first.registry.sealed?
    end

    test "does not execute entrypoints for a blocked report" do
      calls = []
      report = InspectionReport.new(
        mode: :preflight,
        configuration: extension_configuration([]),
        packages: [],
        blockers: [ { code: "blocked", message: "blocked", details: {} } ]
      )

      assert_raises(Loader::IncompatiblePlan) do
        Loader.new(report:, requireer: ->(entrypoint) { calls << entrypoint }).call
      end
      assert_empty calls
    end

    test "fails when an entrypoint does not register its extension" do
      package = extension_package("acme.audit")
      loader = Loader.new(report: ready_report(package), requireer: ->(_entrypoint) { true })

      error = assert_raises(Loader::LoadFailure) { loader.call }

      assert_equal "acme.audit", error.extension_id
      assert_equal "Extensions::Registry::MissingRegistration", error.cause_class
    end

    test "wraps registration failures without exposing the original message" do
      package = extension_package("acme.audit")
      loader = Loader.new(
        report: ready_report(package),
        requireer: ->(_entrypoint) { raise "sensitive provider message" }
      )

      error = assert_raises(Loader::LoadFailure) { loader.call }

      assert_equal "extension_load_failed", error.to_h.fetch(:code)
      assert_nil error.cause
      assert_not_includes error.message, "sensitive"
      assert_not_includes error.to_h.to_s, "sensitive"
    end

    private

    def ready_report(*packages)
      result = CompatibilityPlanner.new(
        packages:,
        platform_version: "0.9.0"
      ).call
      raise result.blockers.inspect if result.blockers.any?

      InspectionReport.new(
        mode: :preflight,
        configuration: extension_configuration(packages),
        packages: packages,
        plan: result.plan
      )
    end

    def extension_configuration(packages)
      Configuration.new({
        "schema_version" => 1,
        "extensions" => packages.map(&:declaration)
      })
    end

    def registering_requireer(packages, calls)
      packages_by_entrypoint = packages.index_by { |package| package.manifest.entrypoint }
      lambda do |entrypoint|
        package = packages_by_entrypoint.fetch(entrypoint)
        calls << entrypoint
        Extensions.register(package.id) do |extension|
          package.manifest.provided_capabilities.each do |capability|
            extension.capability(
              capability.fetch("id"),
              version: capability.fetch("version"),
              provider: -> { package.id }
            )
          end
        end
        true
      end
    end
  end
end

# frozen_string_literal: true

require "test_helper"

module Extensions
  class InspectorTest < ActiveSupport::TestCase
    FakeCatalog = Data.define(:result) do
      def discover = result
    end

    test "inspection reports discovery blockers without executing compatibility" do
      configuration = Configuration.new({ "schema_version" => 1, "extensions" => [] })
      discovery = Catalog::Result.new(
        packages: [],
        blockers: [
          {
            code: "extension_package_missing",
            message: "Configured extension package is not installed",
            details: {}
          }
        ]
      )

      report = Inspector.new(
        configuration:,
        catalog: FakeCatalog.new(discovery),
        platform_version: "0.9.0"
      ).inspect

      assert_equal "blocked", report.status
      assert_nil report.plan
    end

    test "preflight produces an empty ready plan when no extensions are enabled" do
      configuration = Configuration.new({ "schema_version" => 1, "extensions" => [] })
      discovery = Catalog::Result.new(packages: [], blockers: [])

      report = Inspector.new(
        configuration:,
        catalog: FakeCatalog.new(discovery),
        platform_version: "0.9.0"
      ).preflight

      assert report.ready?
      assert_empty report.plan.load_order
      assert_equal 1, report.to_h.fetch(:schema_version)
    end
  end
end

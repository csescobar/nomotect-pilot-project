# frozen_string_literal: true

require "test_helper"

module Extensions
  class LifecycleTest < ActiveSupport::TestCase
    FakeInspector = Data.define(:report) do
      def preflight = report
    end

    test "loads a ready extension plan" do
      configuration = extension_configuration(required: true)
      report = inspection_report(configuration:)
      loader = fake(call: fake(loaded: [ "acme.audit" ]))

      result = Lifecycle.new(
        configuration: configuration,
        inspector_factory: ->(_selected) { FakeInspector.new(report) },
        loader_factory: ->(_ready_report) { loader }
      ).call

      assert_equal "ready", result.status
      assert result.traffic_allowed?
      assert_equal [ "acme.audit" ], result.loaded
      assert_not result.restart_required
    end

    test "skips an incompatible optional extension before loading" do
      configuration = extension_configuration(required: false)
      blocked = inspection_report(
        configuration: configuration,
        blockers: [
          finding("platform_version_incompatible", extension_id: "acme.audit")
        ]
      )
      selected_configurations = []
      inspector_factory = lambda do |selected|
        selected_configurations << selected
        report = selected.enabled.empty? ? inspection_report(configuration: selected) : blocked
        FakeInspector.new(report)
      end
      loader = fake(call: fake(loaded: []))

      result = Lifecycle.new(
        configuration: configuration,
        inspector_factory: inspector_factory,
        loader_factory: ->(_ready_report) { loader }
      ).call

      assert_equal "degraded", result.status
      assert result.traffic_allowed?
      assert_equal [ "acme.audit" ], result.skipped
      assert_equal "optional_extension_skipped", result.warnings.fetch(0).fetch(:code)
      assert_empty selected_configurations.last.enabled
    end

    test "blocks traffic when a required extension is incompatible" do
      configuration = extension_configuration(required: true)
      report = inspection_report(
        configuration: configuration,
        blockers: [
          finding("extension_package_missing", id: "acme.audit")
        ]
      )

      result = Lifecycle.new(
        configuration: configuration,
        inspector_factory: ->(_selected) { FakeInspector.new(report) }
      ).call

      assert_equal "blocked", result.status
      assert_not result.traffic_allowed?
      assert result.restart_required
      assert_equal "extension_package_missing", result.blockers.fetch(0).fetch(:code)
    end

    test "requires a process restart after entrypoint execution fails" do
      configuration = extension_configuration(required: true)
      report = inspection_report(configuration:)
      loader = Object.new
      loader.define_singleton_method(:call) do
        raise Loader::LoadFailure.new("acme.audit", "RuntimeError")
      end

      result = Lifecycle.new(
        configuration: configuration,
        inspector_factory: ->(_selected) { FakeInspector.new(report) },
        loader_factory: ->(_ready_report) { loader }
      ).call

      assert_equal "restart_required", result.status
      assert_not result.traffic_allowed?
      assert result.restart_required
      assert_equal "extension_load_failed", result.blockers.fetch(0).fetch(:code)
    end

    private

    def extension_configuration(required:)
      Configuration.new({
        "schema_version" => 1,
        "extensions" => [
          {
            "id" => "acme.audit",
            "package" => "acme-audit",
            "enabled" => true,
            "required" => required
          }
        ]
      })
    end

    def inspection_report(configuration:, blockers: [])
      InspectionReport.new(
        mode: :preflight,
        configuration: configuration,
        packages: [],
        plan: blockers.empty? ? CompatibilityPlanner::Plan.new("0.9.0", [], []) : nil,
        blockers: blockers
      )
    end

    def finding(code, **details)
      { code: code, message: code, details: details }
    end

    def fake(**methods)
      Object.new.tap do |object|
        methods.each { |name, value| object.define_singleton_method(name) { value } }
      end
    end
  end
end

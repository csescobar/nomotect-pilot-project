# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"
require_relative "../support/extension_package_helper"

class ExtensionFrameworkCertificationTest < ActiveSupport::TestCase
  include ExtensionPackageHelper

  FIXTURE_ROOT = Rails.root.join("test/support/extension_fixtures/certification-audit").freeze

  test "certifies a production-like package from discovery through deterministic loading" do
    configuration = fixture_configuration
    inspector = Extensions::Inspector.new(
      configuration:,
      catalog: Extensions::Catalog.new(
        configuration:,
        resolver: ->(name) { fake_specification(name) }
      ),
      platform_version: "0.8.0"
    )

    first_report = inspector.preflight
    second_report = inspector.preflight
    assert_equal first_report.to_h, second_report.to_h
    assert first_report.ready?
    assert_equal [ "certification.audit" ], first_report.plan.load_order

    components = Extensions::ComponentResolver.new.resolve(first_report.packages.fetch(0))
    assert_equal FIXTURE_ROOT.join("config/extension.schema.json").realpath, components.configuration
    assert_equal [ FIXTURE_ROOT.join("db/migrate").realpath ], components.migration_paths
    assert_equal FIXTURE_ROOT.join("docs/index.md").realpath, components.documentation

    calls = []
    loader = Extensions::Loader.new(
      report: first_report,
      requireer: lambda do |entrypoint|
        calls << entrypoint
        load FIXTURE_ROOT.join("lib", "#{entrypoint}.rb")
      end
    )
    first_result = loader.call

    assert_same first_result, loader.call
    assert_equal [ "certification/audit" ], calls
    assert_equal [ "certification.audit" ], first_result.loaded
    assert_equal [ "certification.audit" ], first_result.registry.registered_ids
    assert first_result.registry.sealed?
  end

  test "certifies the extension-free community core" do
    configuration = Extensions::Configuration.new({
      "schema_version" => 1,
      "extensions" => []
    })
    report = Extensions::Inspector.new(
      configuration:,
      catalog: Extensions::Catalog.new(configuration:, resolver: ->(_name) { }),
      platform_version: "0.8.0"
    ).preflight
    result = Extensions::Loader.new(report:).call

    assert report.ready?
    assert_empty result.loaded
    assert_empty result.registry.registered_ids
    assert result.registry.sealed?
  end

  test "certifies stable blockers for missing incompatible cyclic and duplicate packages" do
    missing_configuration = Extensions::Configuration.new({
      "schema_version" => 1,
      "extensions" => [ extension_declaration("certification.missing") ]
    })
    missing_report = Extensions::Inspector.new(
      configuration: missing_configuration,
      catalog: Extensions::Catalog.new(
        configuration: missing_configuration,
        resolver: ->(_name) { }
      ),
      platform_version: "0.8.0"
    ).preflight
    assert_equal [ "extension_package_missing" ], finding_codes(missing_report)

    incompatible = extension_package("certification.incompatible")
    incompatible_result = Extensions::CompatibilityPlanner.new(
      packages: [ incompatible ],
      platform_version: "0.8.0"
    ).call
    assert_equal [ "platform_version_incompatible" ], finding_codes(incompatible_result)

    first = extension_package(
      "certification.first",
      dependencies: [ extension_dependency("certification.second", ">= 1") ],
      provides: [ provided_capability("certification.shared", 1) ]
    )
    second = extension_package(
      "certification.second",
      dependencies: [ extension_dependency("certification.first", ">= 1") ],
      provides: [ provided_capability("certification.shared", 1) ]
    )
    graph_result = Extensions::CompatibilityPlanner.new(
      packages: [ first, second ],
      platform_version: "0.9.0"
    ).call

    assert_includes finding_codes(graph_result), "extension_dependency_cycle"
    assert_includes finding_codes(graph_result), "capability_provider_conflict"
  end

  test "certifies secret-safe load failure path bounds and pending migration evidence" do
    package = extension_package("certification.failure")
    report = ready_report(package)
    error = assert_raises(Extensions::Loader::LoadFailure) do
      Extensions::Loader.new(
        report:,
        requireer: ->(_entrypoint) { raise "credential=must-not-leak" }
      ).call
    end
    assert_equal "extension_load_failed", error.to_h.fetch(:code)
    assert_nil error.cause
    assert_not_includes error.message, "must-not-leak"

    Dir.mktmpdir("extension-certification") do |directory|
      root = Pathname(directory)
      FileUtils.cp_r("#{FIXTURE_ROOT}/.", root)
      outside = root.dirname.join("outside-extension-documentation.md")
      File.write(outside, "outside")
      FileUtils.rm_f(root.join("docs/index.md"))
      FileUtils.ln_s(outside, root.join("docs/index.md"))
      escaped = fixture_package(root:)

      assert_raises(Extensions::ComponentResolver::InvalidComponent) do
        Extensions::ComponentResolver.new.resolve(escaped)
      end
    ensure
      FileUtils.rm_f(outside) if outside
    end

    fixture = fixture_package
    state = Extensions::InstalledState.new(
      report: ready_report(fixture, platform_version: "0.8.0"),
      migration_context_factory: lambda do |_paths|
        fake_object(
          migrations_status: [
            [ "down", "20260728130000", "Create certification audit events" ]
          ]
        )
      end
    ).call.fetch(0)
    assert_equal "20260728130000", state.dig("pending_migrations", 0, "version")
    assert_equal "certification.audit", state.dig("pending_migrations", 0, "namespace")

    upgrade_state = installed_platform_state
    upgrade_state["extensions"] = [ state ]
    upgrade_report = Upgrades::Inspector.new(
      manifest: upgrade_manifest,
      detector: fake_object(call: upgrade_state)
    ).preflight
    assert_includes finding_codes(upgrade_report), "pending_extension_migrations"
    assert_nil upgrade_report.plan
  end

  private

  def fixture_configuration
    Extensions::Configuration.new(
      {
        "schema_version" => 1,
        "extensions" => [
          {
            "id" => "certification.audit",
            "package" => "certification-audit",
            "enabled" => true,
            "required" => true
          }
        ]
      },
      path: Rails.root.join("config/extensions.yml")
    )
  end

  def fake_specification(name)
    return unless name == "certification-audit"

    fake_object(full_gem_path: FIXTURE_ROOT.to_s)
  end

  def fixture_package(root: FIXTURE_ROOT)
    manifest = Extensions::Manifest.load(root.join("platform-extension.yml"))
    Extensions::Package.new(
      declaration: fixture_configuration.enabled.fetch(0),
      root:,
      manifest:
    )
  end

  def ready_report(package, platform_version: "0.9.0")
    result = Extensions::CompatibilityPlanner.new(
      packages: [ package ],
      platform_version:
    ).call
    raise result.blockers.inspect if result.blockers.any?

    Extensions::InspectionReport.new(
      mode: :preflight,
      configuration: Extensions::Configuration.new({
        "schema_version" => 1,
        "extensions" => [ package.declaration ]
      }),
      packages: [ package ],
      plan: result.plan
    )
  end

  def finding_codes(value)
    value.blockers.pluck(:code)
  end

  def fake_object(**methods)
    Object.new.tap do |object|
      methods.each { |name, value| object.define_singleton_method(name) { value } }
    end
  end

  def installed_platform_state
    {
      "schema_version" => 2,
      "observed_at" => "2026-07-28T12:00:00Z",
      "environment" => "production",
      "platform" => { "version" => "0.8.0" },
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
      "deployment" => { "contract_version" => nil, "profile" => "production" },
      "database" => {
        "available" => true,
        "schema_version" => "20260728000000",
        "pending_migrations" => []
      },
      "generated_artifacts" => { "current" => true, "checks" => [] },
      "extensions" => []
    }
  end

  def upgrade_manifest
    Upgrades::Manifest.new(
      "schema_version" => 1,
      "id" => "extension-certification-upgrade",
      "source" => { "requirement" => ">= 0.8.0, < 0.9.0" },
      "target" => { "version" => "0.9.0" },
      "compatibility" => {
        "rails" => "~> 8.1.0",
        "ruby" => "~> 4.0.0",
        "postgresql" => ">= 18.0.0, < 19.0.0",
        "contracts" => {
          "installation-state" => 1,
          "upgrade-history" => 1
        }
      },
      "backup" => { "required" => false, "evidence" => [] },
      "operations" => [
        {
          "id" => "verify",
          "type" => "validation",
          "description" => "Verify the target extension state",
          "reversible" => true,
          "requires" => []
        }
      ],
      "deprecations" => []
    )
  end
end

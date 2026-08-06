# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"

class ApplicationExtensionSampleTest < ActiveSupport::TestCase
  SAMPLE_DECLARATION = {
    "id" => "nomotect.sample-audit",
    "package" => "sample-audit",
    "enabled" => true,
    "required" => false
  }.freeze

  test "certifies community fallback and the application-owned sample lifecycle" do
    default_configuration = Extensions::Configuration.load_default
    assert_empty default_configuration.enabled

    community_report = Extensions::Inspector.new(configuration: default_configuration).preflight
    community_result = Extensions::Loader.new(report: community_report).call
    assert community_report.ready?
    assert_empty community_result.loaded

    incompatible = Extensions::Configuration.new({
      "schema_version" => 1,
      "extensions" => [ SAMPLE_DECLARATION.dup ]
    })
    degraded = Extensions::Lifecycle.new(
      configuration: incompatible,
      inspector_factory: lambda do |selected|
        Extensions::Inspector.new(configuration: selected, platform_version: "1.0.0")
      end
    ).call
    assert_equal "degraded", degraded.status
    assert_equal [ "nomotect.sample-audit" ], degraded.skipped
    assert degraded.traffic_allowed?

    enabled = Extensions::Configuration.new({
      "schema_version" => 1,
      "extensions" => [ SAMPLE_DECLARATION.dup ]
    })
    report = Extensions::Inspector.new(configuration: enabled).preflight
    result = Extensions::Loader.new(report:).call

    assert report.ready?
    assert_equal [ "nomotect.sample-audit" ], result.loaded
    entry = result.registry.fetch("nomotect.sample-audit")
    provider = entry.capabilities.fetch("sample.audit-events").fetch(:provider)
    assert_equal({ event_id: "evt-1", recorded: true }, provider.call(id: "evt-1"))
    assert result.registry.sealed?
  end

  test "rejects an entrypoint symlink that escapes the package lib directory" do
    Dir.mktmpdir do |directory|
      root = Pathname(directory)
      FileUtils.cp_r(Rails.root.join("application/extensions/sample-audit/."), root)
      entrypoint = root.join("lib/nomotect/sample_audit.rb")
      outside = root.parent.join("outside-sample-entrypoint.rb")
      outside.write("raise 'must not execute'\n")
      entrypoint.delete
      entrypoint.make_symlink(outside)
      manifest = Extensions::Manifest.load(root.join("platform-extension.yml"))
      package = Extensions::Package.new(
        declaration: SAMPLE_DECLARATION.dup,
        root:,
        manifest:
      )

      assert_raises(Extensions::Package::InvalidEntrypoint) { package.entrypoint_path }
    ensure
      outside&.delete if outside&.exist?
    end
  end
end

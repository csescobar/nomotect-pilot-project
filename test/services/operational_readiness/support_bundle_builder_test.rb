# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module OperationalReadiness
  class SupportBundleBuilderTest < ActiveSupport::TestCase
    setup do
      @root = Pathname(Dir.mktmpdir("support-bundle-", Rails.root.join("tmp")))
      @output = @root.join("bundle")
    end

    teardown { FileUtils.rm_rf(@root) }

    test "builds a checksum-bound local bundle with restricted permissions" do
      registry = DiagnosticCollectorRegistry.new.register("platform") do
        { "version" => "0.9.0", "token" => "must-not-leak" }
      end
      manifest = builder(registry:).build!
      report = @output.join("reports/platform.json")

      assert_equal false, manifest.data.fetch("automated_upload")
      assert_equal 0o700, @output.stat.mode & 0o777
      assert_equal 0o600, report.stat.mode & 0o777
      refute_includes report.read, "must-not-leak"
      assert_equal(
        manifest.files.first.fetch("checksum"),
        "sha256:#{Digest::SHA256.file(report).hexdigest}"
      )
    end

    test "inspection does not write output and size failures remove partial state" do
      registry = DiagnosticCollectorRegistry.new.register("large") { { "value" => "x" * 200 } }

      manifest = builder(registry:, max_entry_bytes: 500).inspect
      assert_equal "large", manifest.files.first.fetch("id")
      refute @output.exist?

      assert_raises(SupportBundleBuilder::SizeLimitExceeded) do
        builder(registry:, max_entry_bytes: 10).build!
      end
      refute @output.exist?
    end

    private

    def builder(registry:, max_entry_bytes: 500)
      SupportBundleBuilder.new(
        registry:,
        output: @output,
        max_entry_bytes:,
        max_bundle_bytes: 1_000,
        source: {
          "platform_version" => "0.9.0",
          "source_commit" => "a" * 40,
          "environment" => "production-like"
        },
        clock: -> { Time.iso8601("2026-07-31T00:00:00Z") }
      )
    end
  end
end

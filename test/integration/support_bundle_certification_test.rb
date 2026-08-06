# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class SupportBundleCertificationTest < ActiveSupport::TestCase
  test "certifies allowlisted credential-free diagnostics without upload" do
    Dir.mktmpdir("support-certification-", Rails.root.join("tmp")) do |directory|
      installed_state = lambda do
        {
          "platform" => { "version" => "0.9.0" },
          "database" => {
            "available" => true,
            "message" => "postgresql://operator:private@database/app"
          },
          "extensions" => [],
          "contact" => "support@example.com"
        }
      end
      environment = {
        "DATABASE_URL" => "postgresql://operator:private@database/app",
        "SECRET_KEY_BASE" => "private-value"
      }
      registry = OperationalReadiness::DefaultDiagnosticCollectors.new(
        installed_state:,
        environment:,
        operational_health: -> {
          {
            "schema_version" => 1,
            "observed_at" => "2026-07-31T00:00:00Z",
            "status" => "healthy",
            "summary" => { "healthy" => 5, "degraded" => 0, "unhealthy" => 0, "unknown" => 0 },
            "signals" => []
          }
        }
      ).registry
      output = Pathname(directory).join("bundle")
      manifest = OperationalReadiness::SupportBundleBuilder.new(
        registry:,
        output:,
        source: {
          "platform_version" => "0.9.0",
          "source_commit" => "b" * 40,
          "environment" => "production-like"
        },
        clock: -> { Time.iso8601("2026-07-31T00:00:00Z") }
      ).build!

      contents = output.glob("**/*").select(&:file?).map(&:read).join
      refute_includes contents, "operator:private"
      refute_includes contents, "support@example.com"
      refute_includes contents, "private-value"
      assert_equal %w[configuration operational_health platform], manifest.files.pluck("id")
      assert_equal false, manifest.data.fetch("automated_upload")
    end
  end
end

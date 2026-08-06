# frozen_string_literal: true

require "test_helper"

module Extensions
  class ManifestTest < ActiveSupport::TestCase
    test "accepts a strict extension contract" do
      manifest = Manifest.new(manifest_data)

      assert_equal "acme.audit-plus", manifest.id
      assert_equal "1.2.0", manifest.version
      assert_equal ">= 0.9.0, < 1.0.0", manifest.platform_requirement
      assert_equal [ "audit.analytics" ], manifest.provided_capabilities.pluck("id")
    end

    test "rejects unsupported fields" do
      data = manifest_data.merge("license_key" => "secret")

      error = assert_raises(Manifest::InvalidManifest) { Manifest.new(data) }
      assert_includes error.message, "unsupported keys"
    end

    test "rejects component path traversal" do
      data = manifest_data
      data["components"]["documentation"] = "../private"

      error = assert_raises(Manifest::InvalidManifest) { Manifest.new(data) }
      assert_includes error.message, "bounded relative path"
    end

    test "rejects duplicate capability identifiers" do
      data = manifest_data
      data["capabilities"]["provides"] << data["capabilities"]["provides"].first.dup

      error = assert_raises(Manifest::InvalidManifest) { Manifest.new(data) }
      assert_includes error.message, "ids must be unique"
    end

    test "requires a semantic extension version" do
      data = manifest_data
      data["extension"]["version"] = "1"

      error = assert_raises(Manifest::InvalidManifest) { Manifest.new(data) }
      assert_includes error.message, "semantic versioning"
    end

    private

    def manifest_data
      {
        "schema_version" => 1,
        "extension" => {
          "id" => "acme.audit-plus",
          "version" => "1.2.0",
          "contract_version" => 1,
          "entrypoint" => "acme/audit_plus"
        },
        "platform" => { "requirement" => ">= 0.9.0, < 1.0.0" },
        "capabilities" => {
          "provides" => [ { "id" => "audit.analytics", "version" => 1 } ],
          "requires" => [ { "id" => "audit.events", "requirement" => ">= 1, < 2" } ]
        },
        "dependencies" => [
          { "id" => "acme.reporting", "requirement" => "~> 2.0" }
        ],
        "components" => {
          "configuration" => "config/extension.schema.json",
          "migrations" => {
            "namespace" => "acme.audit-plus",
            "paths" => [ "db/migrate" ]
          },
          "routes" => { "namespace" => "acme.audit-plus" },
          "assets" => { "namespace" => "acme-audit-plus" },
          "documentation" => "docs/index.md"
        },
        "security" => { "trust" => "trusted_in_process" }
      }
    end
  end
end

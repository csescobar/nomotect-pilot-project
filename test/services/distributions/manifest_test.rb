# frozen_string_literal: true

require "test_helper"

module Distributions
  class ManifestTest < ActiveSupport::TestCase
    test "accepts the supported GitHub Release and GHCR channel contract" do
      manifest = Manifest.new(manifest_data)

      assert_equal "0.8.0", manifest.version
      assert_equal "v0.8.0", manifest.tag
      assert_equal Manifest::CHANNEL_IDS, manifest.channels.pluck("id").sort
      assert_equal Manifest::ARTIFACT_IDS, manifest.artifacts.sort
    end

    test "rejects a tag that does not match the canonical version" do
      data = manifest_data
      data["release"]["tag"] = "v0.8.1"

      error = assert_raises(Manifest::InvalidManifest) { Manifest.new(data) }
      assert_includes error.message, "tag must equal"
    end

    test "requires both supported channels exactly once" do
      data = manifest_data
      data["channels"] << data["channels"].first.dup

      error = assert_raises(Manifest::InvalidManifest) { Manifest.new(data) }
      assert_includes error.message, "channel ids must be unique"
    end

    test "rejects rebuilding the release image" do
      data = manifest_data
      data["channels"].last["rebuild"] = true

      error = assert_raises(Manifest::InvalidManifest) { Manifest.new(data) }
      assert_includes error.message, "rebuild must equal false"
    end

    test "rejects latest before the stable release gate" do
      data = manifest_data
      data["channels"].last["allow_latest"] = true

      error = assert_raises(Manifest::InvalidManifest) { Manifest.new(data) }
      assert_includes error.message, "allow_latest must equal false"
    end

    test "requires the complete release artifact set" do
      data = manifest_data
      data["artifacts"].delete("provenance")

      error = assert_raises(Manifest::InvalidManifest) { Manifest.new(data) }
      assert_includes error.message, "complete release artifact set"
    end

    test "rejects unsupported manifest fields" do
      data = manifest_data.merge("credentials" => { "token" => "not-allowed" })

      error = assert_raises(Manifest::InvalidManifest) { Manifest.new(data) }
      assert_includes error.message, "unsupported keys"
    end

    private

    def manifest_data
      {
        "schema_version" => 1,
        "release" => {
          "version" => "0.8.0",
          "tag" => "v0.8.0",
          "commit" => "a" * 40,
          "release_metadata_digest" => "b" * 64,
          "compatibility_digest" => "c" * 64
        },
        "repository" => {
          "identity" => "repository_context",
          "source_branch" => "main"
        },
        "channels" => [
          {
            "id" => "github_release",
            "enabled" => true,
            "prerelease" => true
          },
          {
            "id" => "ghcr",
            "enabled" => true,
            "semantic_tags" => %w[full minor],
            "architectures" => %w[linux/amd64 linux/arm64],
            "rebuild" => false,
            "allow_latest" => false
          }
        ],
        "artifacts" => Manifest::ARTIFACT_IDS.dup,
        "policy" => {
          "approval_environment" => "release",
          "release_requires_approval" => true,
          "overwrite" => false
        },
        "recovery" => {
          "strategy" => "resume_forward",
          "partial_publication" => "operator_review"
        }
      }
    end
  end
end

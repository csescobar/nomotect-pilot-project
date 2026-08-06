# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module Distributions
  class GithubReleasePlanTest < ActiveSupport::TestCase
    setup do
      @directory = Pathname(Dir.mktmpdir("distribution-bundle-", Rails.root.join("tmp")))
      write_artifacts
    end

    teardown { FileUtils.rm_rf(@directory) }

    test "plans an immutable prerelease from the complete verified bundle" do
      plan = GithubReleasePlan.new(manifest: manifest, artifact_directory: @directory)

      assert_equal "v0.8.0", plan.tag
      assert_equal "a" * 40, plan.target_commit
      assert plan.prerelease?
      assert_equal 11, plan.asset_paths.size
      assert_equal Manifest::ARTIFACT_IDS, plan.artifacts.pluck(:id).sort
    end

    test "rejects a modified artifact" do
      @directory.join("release-notes.md").write("modified")

      error = assert_raises(GithubReleasePlan::InvalidBundle) do
        GithubReleasePlan.new(manifest: manifest, artifact_directory: @directory)
      end

      assert_match(/checksum is missing or invalid/, error.message)
    end

    test "rejects symbolic-link artifacts" do
      @directory.join("release-notes.md").delete
      File.symlink(Rails.root.join("README.md"), @directory.join("release-notes.md"))

      error = assert_raises(GithubReleasePlan::InvalidBundle) do
        GithubReleasePlan.new(manifest: manifest, artifact_directory: @directory)
      end

      assert_match(/symbolic link/, error.message)
    end

    private

    def write_artifacts
      GithubReleasePlan::ARTIFACT_FILES.each_value do |filename|
        next if filename == "SHA256SUMS"

        @directory.join(filename).write("#{filename}\n")
      end
      entries = GithubReleasePlan::ARTIFACT_FILES.each_value.filter_map do |filename|
        next if filename == "SHA256SUMS"

        path = @directory.join(filename)
        "#{Digest::SHA256.file(path).hexdigest}  #{filename}"
      end
      @directory.join("SHA256SUMS").write("#{entries.join("\n")}\n")
    end

    def manifest
      Manifest.new(
        "schema_version" => 1,
        "release" => {
          "version" => "0.8.0",
          "tag" => "v0.8.0",
          "commit" => "a" * 40,
          "release_metadata_digest" => "b" * 64,
          "compatibility_digest" => "c" * 64
        },
        "repository" => { "identity" => "repository_context", "source_branch" => "main" },
        "channels" => [
          { "id" => "github_release", "enabled" => true, "prerelease" => true },
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
      )
    end
  end
end

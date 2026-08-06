# frozen_string_literal: true

require "test_helper"

module Distributions
  class ChannelObserverTest < ActiveSupport::TestCase
    setup do
      @commit = "a" * 40
      @digest = "sha256:#{'d' * 64}"
      @repository = "owner/platform"
      @manifest = Manifest.new(manifest_data)
      @observer = ChannelObserver.new(
        manifest: @manifest,
        repository: @repository,
        image_digest: @digest
      )
    end

    test "reports absent publication targets when the commit image is available" do
      github = @observer.github_release(
        "release" => provider_state(404),
        "tag" => provider_state(404)
      )
      ghcr = @observer.ghcr(
        "commit_tag" => provider_state(200, "digest" => @digest),
        "full_tag" => provider_state(404),
        "minor_tag" => provider_state(404)
      )

      assert_equal "absent", github.status
      assert_equal "absent", ghcr.status
      assert_empty github.findings
      assert_empty ghcr.findings
    end

    test "reports canonical published channel state" do
      github = @observer.github_release(
        "release" => provider_state(
          200,
          "target_commitish" => @commit,
          "html_url" => "https://github.com/owner/platform/releases/tag/v0.8.0"
        ),
        "tag" => provider_state(200, "target_commit" => @commit)
      )
      ghcr = @observer.ghcr(
        "commit_tag" => provider_state(200, "digest" => @digest),
        "full_tag" => provider_state(200, "digest" => @digest),
        "minor_tag" => provider_state(200, "digest" => @digest)
      )

      assert_equal "available", github.status
      assert_equal @commit, github.observed_commit
      assert_equal "https://github.com/owner/platform/releases/tag/v0.8.0",
        github.immutable_reference
      assert_equal "available", ghcr.status
      assert_equal "ghcr.io/owner/platform@#{@digest}", ghcr.immutable_reference
    end

    test "fails closed for partial and conflicting channel state" do
      github = @observer.github_release(
        "release" => provider_state(200, "target_commitish" => @commit),
        "tag" => provider_state(404)
      )
      ghcr = @observer.ghcr(
        "commit_tag" => provider_state(200, "digest" => @digest),
        "full_tag" => provider_state(200, "digest" => @digest),
        "minor_tag" => provider_state(200, "digest" => "sha256:#{'e' * 64}")
      )

      assert_equal "partial", github.status
      assert_equal [ "channel_partial" ], github.findings.pluck("code")
      assert_equal "conflict", ghcr.status
      assert_equal [ "image_digest_mismatch" ], ghcr.findings.pluck("code")
    end

    test "rejects provider observations containing unexpected fields" do
      error = assert_raises(ChannelObserver::InvalidObservation) do
        @observer.github_release(
          "release" => provider_state(404).merge("authorization" => "secret"),
          "tag" => provider_state(404)
        )
      end

      assert_includes error.message, "unsupported keys"
    end

    private

    def provider_state(status_code, values = {})
      { "status_code" => status_code }.merge(values)
    end

    def manifest_data
      {
        "schema_version" => 1,
        "release" => {
          "version" => "0.8.0",
          "tag" => "v0.8.0",
          "commit" => @commit,
          "release_metadata_digest" => "b" * 64,
          "compatibility_digest" => "c" * 64
        },
        "repository" => {
          "identity" => "repository_context",
          "source_branch" => "main"
        },
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
      }
    end
  end
end

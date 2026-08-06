# frozen_string_literal: true

require "test_helper"

module Distributions
  class GhcrPromotionPlanTest < ActiveSupport::TestCase
    test "promotes the existing digest to full and minor semantic tags" do
      plan = GhcrPromotionPlan.new(
        manifest: manifest,
        repository: "Owner/Platform",
        digest: "sha256:#{'d' * 64}"
      )

      assert_equal "ghcr.io/owner/platform@sha256:#{'d' * 64}", plan.immutable_reference
      assert_equal(
        %w[ghcr.io/owner/platform:0.8.0 ghcr.io/owner/platform:0.8],
        plan.semantic_tags
      )
      assert_equal "ghcr.io/owner/platform:sha-aaaaaaaaaaaa", plan.commit_tag
      refute plan.to_h.fetch(:rebuild)
      refute plan.to_h.fetch(:latest)
    end

    test "rejects a non-immutable digest" do
      assert_raises(GhcrPromotionPlan::InvalidPromotion) do
        GhcrPromotionPlan.new(manifest: manifest, repository: "owner/platform", digest: "latest")
      end
    end

    private

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

# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module Distributions
  class VerifierTest < ActiveSupport::TestCase
    setup do
      @directory = Pathname(Dir.mktmpdir("distribution-verifier-", Rails.root.join("tmp")))
      write_artifacts
    end

    teardown { FileUtils.rm_rf(@directory) }

    test "records verified channels and canonical artifact evidence" do
      evidence = verifier.verify

      assert verifier.ready?
      assert_equal "published", evidence.fetch(:status)
      assert_equal %w[verified verified], evidence.fetch(:channels).pluck(:status)
      assert_equal 11, evidence.fetch(:artifacts).size
      assert_match(/\A[a-f0-9]{64}\z/, evidence.dig(:source, :manifest_digest))
    end

    test "fails closed when a channel resolves to another commit" do
      states = channel_states
      states[0] = channel_state(
        channel: "github_release",
        immutable_reference: github_reference,
        observed_commit: "e" * 40
      )
      evidence = verifier(states).verify

      refute verifier(states).ready?
      assert_equal "verification_failed", evidence.fetch(:status)
      assert_equal [ "source_commit_mismatch" ], evidence.fetch(:findings).pluck(:code)
    end

    test "fails closed when channel evidence is duplicated" do
      states = channel_states
      states << states.last
      candidate = verifier(states)

      refute candidate.ready?
      assert_equal [ "evidence_incomplete" ], candidate.verify.fetch(:findings).pluck(:code)
    end

    private

    def verifier(states = channel_states)
      Verifier.new(
        manifest: manifest,
        repository: "owner/platform",
        github_release_plan: GithubReleasePlan.new(
          manifest: manifest,
          artifact_directory: @directory
        ),
        ghcr_plan: GhcrPromotionPlan.new(
          manifest: manifest,
          repository: "owner/platform",
          digest: image_digest
        ),
        channel_states: states
      )
    end

    def channel_states
      [
        channel_state(channel: "github_release", immutable_reference: github_reference),
        channel_state(channel: "ghcr", immutable_reference: "ghcr.io/owner/platform@#{image_digest}")
      ]
    end

    def channel_state(channel:, immutable_reference:, observed_commit: "a" * 40)
      ChannelState.new(
        "schema_version" => 1,
        "channel" => channel,
        "repository" => "owner/platform",
        "version" => "0.8.0",
        "tag" => "v0.8.0",
        "status" => "available",
        "immutable_reference" => immutable_reference,
        "observed_commit" => observed_commit,
        "findings" => []
      )
    end

    def github_reference = "https://github.com/owner/platform/releases/tag/v0.8.0"
    def image_digest = "sha256:#{'d' * 64}"

    def write_artifacts
      GithubReleasePlan::ARTIFACT_FILES.each_value do |filename|
        next if filename == "SHA256SUMS"

        @directory.join(filename).write("#{filename}\n")
      end
      checksums = GithubReleasePlan::ARTIFACT_FILES.each_value.filter_map do |filename|
        next if filename == "SHA256SUMS"

        "#{Digest::SHA256.file(@directory.join(filename)).hexdigest}  #{filename}"
      end
      @directory.join("SHA256SUMS").write("#{checksums.join("\n")}\n")
    end

    def manifest
      @manifest ||= Manifest.new(
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

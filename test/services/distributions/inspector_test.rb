# frozen_string_literal: true

require "test_helper"

module Distributions
  class InspectorTest < ActiveSupport::TestCase
    test "reports a ready preflight with absent compatible channels" do
      report = inspector.preflight

      assert report.ready?
      assert_equal "warnings", report.status
      assert_empty report.blockers
      assert_equal [ "approval_required" ], report.operator_actions.pluck(:code)
    end

    test "inspection warns when remote observations are unavailable" do
      report = inspector(channel_states: []).inspect

      assert report.ready?
      assert_equal 2, report.warnings.count
      assert_equal [ "remote_state_unavailable" ], report.warnings.pluck(:code).uniq
    end

    test "preflight blocks when remote observations are unavailable" do
      report = inspector(channel_states: []).preflight

      refute report.ready?
      assert_equal 2, report.blockers.count
      assert_equal [ "remote_state_unavailable" ], report.blockers.pluck(:code).uniq
    end

    test "blocks a conflicting GitHub Release" do
      states = channel_states
      states[0] = channel_state(
        channel: "github_release",
        status: "conflict",
        observed_commit: "d" * 40
      )

      report = inspector(channel_states: states).preflight

      assert_includes report.blockers.pluck(:code), "release_conflict"
    end

    test "blocks publication replay during preflight" do
      states = channel_states.map do |state|
        channel_state(
          channel: state.channel,
          status: "available",
          observed_commit: source_commit
        )
      end

      report = inspector(channel_states: states).preflight

      assert_equal %w[publication_replay publication_replay], report.blockers.pluck(:code)
    end

    test "blocks source branch and commit mismatches" do
      report = inspector(source_branch: "feature", source_commit: "e" * 40).preflight

      assert_includes report.blockers.pluck(:code), "source_not_main"
      assert_includes report.blockers.pluck(:code), "source_commit_mismatch"
    end

    test "blocks modified release metadata" do
      metadata = release_metadata.merge("target_version" => "0.8.1")

      report = inspector(release_metadata: metadata).preflight

      assert_includes report.blockers.pluck(:code), "release_metadata_mismatch"
    end

    private

    def inspector(
      channel_states: self.channel_states,
      release_metadata: self.release_metadata,
      source_branch: "main",
      source_commit: self.source_commit
    )
      Distributions::Inspector.new(
        manifest: manifest,
        release_metadata: release_metadata,
        compatibility: compatibility,
        repository: "owner/platform",
        source_commit: source_commit,
        source_branch: source_branch,
        channel_states: channel_states
      )
    end

    def manifest
      @manifest ||= Manifest.new(
        manifest_data(
          release_metadata_digest: digest(release_metadata),
          compatibility_digest: digest(compatibility)
        )
      )
    end

    def release_metadata
      {
        "schema_version" => 1,
        "source_version" => "0.7.0",
        "target_version" => "0.8.0",
        "release_impact" => "minor",
        "fragment_ids" => [ "release" ],
        "fragment_digest" => "f" * 64,
        "compatibility_digest" => digest(compatibility)
      }
    end

    def compatibility
      {
        "schema_version" => 1,
        "platform_version" => "0.8.0",
        "contracts" => { "release_metadata" => 1 }
      }
    end

    def digest(value)
      Digest::SHA256.hexdigest(Releases::CanonicalJson.generate(value))
    end

    def source_commit = "a" * 40

    def channel_states
      [
        channel_state(channel: "github_release"),
        channel_state(channel: "ghcr")
      ]
    end

    def channel_state(channel:, status: "absent", observed_commit: nil)
      ChannelState.new(
        "schema_version" => 1,
        "channel" => channel,
        "repository" => "owner/platform",
        "version" => "0.8.0",
        "tag" => "v0.8.0",
        "status" => status,
        "immutable_reference" => status == "absent" ? nil : "immutable",
        "observed_commit" => observed_commit,
        "findings" => []
      )
    end

    def manifest_data(release_metadata_digest:, compatibility_digest:)
      {
        "schema_version" => 1,
        "release" => {
          "version" => "0.8.0",
          "tag" => "v0.8.0",
          "commit" => source_commit,
          "release_metadata_digest" => release_metadata_digest,
          "compatibility_digest" => compatibility_digest
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

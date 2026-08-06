# frozen_string_literal: true

require "digest"

module Distributions
  class Inspector
    def initialize(
      manifest:,
      release_metadata:,
      compatibility:,
      repository:,
      source_commit:,
      source_branch:,
      channel_states:
    )
      @manifest = manifest
      @release_metadata = release_metadata
      @compatibility = compatibility
      @repository = repository
      @source_commit = source_commit
      @source_branch = source_branch
      @channel_states = channel_states
    end

    def inspect
      build_report(:inspect, include_remote_blockers: false)
    end

    def preflight
      build_report(:preflight, include_remote_blockers: true)
    end

    private

    attr_reader :manifest, :release_metadata, :compatibility, :repository,
      :source_commit, :source_branch, :channel_states

    def build_report(mode, include_remote_blockers:)
      blockers = local_blockers
      warnings = []
      inspect_channel_states(blockers, warnings, include_remote_blockers:)

      InspectionReport.new(
        mode: mode,
        manifest: manifest,
        repository: repository,
        source_commit: source_commit,
        channel_states: channel_states,
        blockers: blockers,
        warnings: warnings,
        operator_actions: operator_actions
      )
    end

    def local_blockers
      findings = []
      compare(findings, "source_not_main", "main", source_branch)
      compare(findings, "source_commit_mismatch", manifest.commit, source_commit)
      compare(
        findings,
        "release_metadata_mismatch",
        manifest.version,
        release_metadata["target_version"]
      )
      compare(
        findings,
        "release_metadata_mismatch",
        manifest.data.dig("release", "release_metadata_digest"),
        digest(release_metadata)
      )
      compare(
        findings,
        "compatibility_digest_mismatch",
        manifest.data.dig("release", "compatibility_digest"),
        digest(compatibility)
      )
      compare(
        findings,
        "compatibility_digest_mismatch",
        release_metadata["compatibility_digest"],
        digest(compatibility)
      )
      findings
    end

    def inspect_channel_states(blockers, warnings, include_remote_blockers:)
      states = channel_states.index_by(&:channel)
      Manifest::CHANNEL_IDS.each do |channel|
        state = states[channel]
        unless state
          target = include_remote_blockers ? blockers : warnings
          target << finding(
            "remote_state_unavailable",
            "Required distribution channel state is unavailable",
            channel: channel
          )
          next
        end

        inspect_channel_identity(state, blockers)
        inspect_channel_status(state, blockers, warnings, include_remote_blockers:)
      end
    end

    def inspect_channel_identity(state, blockers)
      details = { channel: state.channel }
      compare(blockers, "channel_repository_mismatch", repository, state.repository, details)
      compare(blockers, "channel_version_mismatch", manifest.version, state.version, details)
      compare(blockers, "channel_tag_mismatch", manifest.tag, state.tag, details)
    end

    def inspect_channel_status(state, blockers, warnings, include_remote_blockers:)
      case state.status
      when "absent"
        nil
      when "available"
        if state.observed_commit == manifest.commit
          target = include_remote_blockers ? blockers : warnings
          target << finding(
            "publication_replay",
            "The immutable channel object already exists for this release",
            channel: state.channel,
            immutable_reference: state.immutable_reference
          )
        else
          blockers << conflict_finding(state)
        end
      when "conflict"
        blockers << conflict_finding(state)
      when "partial"
        blockers << finding(
          "channel_partial",
          "Distribution channel state is incomplete",
          channel: state.channel
        )
      when "unavailable"
        target = include_remote_blockers ? blockers : warnings
        target << finding(
          "remote_state_unavailable",
          "Distribution channel could not be inspected",
          channel: state.channel
        )
      end
    end

    def conflict_finding(state)
      code = state.channel == "github_release" ? "release_conflict" : "tag_conflict"
      finding(
        code,
        "An immutable channel object conflicts with the approved release",
        channel: state.channel,
        observed_commit: state.observed_commit
      )
    end

    def operator_actions
      [
        finding(
          "approval_required",
          "Approve publication through the protected release environment",
          environment: manifest.data.dig("policy", "approval_environment")
        )
      ]
    end

    def digest(value)
      Digest::SHA256.hexdigest(Releases::CanonicalJson.generate(value))
    end

    def compare(findings, code, expected, actual, details = {})
      return if expected == actual

      findings << finding(
        code,
        "Distribution input does not match the approved manifest",
        details.merge(expected: expected, actual: actual)
      )
    end

    def finding(code, message, details = {})
      { code: code, message: message, details: details }
    end
  end
end

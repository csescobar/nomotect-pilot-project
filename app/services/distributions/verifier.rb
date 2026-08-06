# frozen_string_literal: true

require "digest"

module Distributions
  class Verifier
    attr_reader :manifest, :repository, :github_release_plan, :ghcr_plan, :channel_states

    def initialize(
      manifest:,
      repository:,
      github_release_plan:,
      ghcr_plan:,
      channel_states:
    )
      @manifest = manifest
      @repository = repository
      @github_release_plan = github_release_plan
      @ghcr_plan = ghcr_plan
      @channel_states = channel_states
    end

    def verify
      findings = verification_findings
      {
        schema_version: 1,
        publication_id: "#{manifest.version}-#{manifest.commit[0, 12]}",
        version: manifest.version,
        tag: manifest.tag,
        source: {
          repository: repository,
          commit: manifest.commit,
          manifest_digest: manifest_digest
        },
        status: findings.empty? ? "published" : "verification_failed",
        channels: channel_evidence,
        artifacts: artifact_evidence,
        findings: findings
      }
    end

    def ready? = verification_findings.empty?

    private

    def verification_findings
      findings = duplicate_channel_findings
      states = channel_states.index_by(&:channel)
      Manifest::CHANNEL_IDS.each do |channel|
        state = states[channel]
        issue = channel_finding(channel, state)
        findings << issue if issue
      end
      findings
    end

    def duplicate_channel_findings
      channel_states
        .group_by(&:channel)
        .select { |_channel, states| states.many? }
        .map { finding("evidence_incomplete", "Channel evidence is duplicated") }
    end

    def channel_finding(channel, state)
      return finding("evidence_incomplete", "Required channel evidence is missing") unless state
      return finding("channel_repository_mismatch", "Channel evidence belongs to another repository") unless
        state.repository == repository
      return finding("channel_version_mismatch", "Channel evidence belongs to another version") unless
        state.version == manifest.version
      return finding("channel_tag_mismatch", "Channel evidence belongs to another tag") unless
        state.tag == manifest.tag
      return finding("evidence_incomplete", "Channel publication is not available") unless state.status == "available"
      return finding("source_commit_mismatch", "Channel evidence belongs to another commit") unless
        state.observed_commit == manifest.commit
      return finding("evidence_incomplete", "Channel immutable reference is missing") if
        state.immutable_reference.blank?
      return finding("image_digest_mismatch", "GHCR evidence resolves to another digest") if
        channel == "ghcr" && state.immutable_reference != ghcr_plan.immutable_reference
      finding("release_conflict", "GitHub Release evidence resolves to another release") if
        channel == "github_release" && state.immutable_reference != github_release_reference
    end

    def channel_evidence
      states = channel_states.index_by(&:channel)
      Manifest::CHANNEL_IDS.map do |channel|
        state = states[channel]
        {
          id: channel,
          status: state && channel_verified?(state) ? "verified" : "failed",
          immutable_reference: state&.immutable_reference
        }
      end
    end

    def channel_verified?(state)
      state.status == "available" &&
        state.repository == repository &&
        state.version == manifest.version &&
        state.tag == manifest.tag &&
        state.observed_commit == manifest.commit &&
        state.immutable_reference.present? &&
        expected_reference(state.channel) == state.immutable_reference
    end

    def expected_reference(channel)
      channel == "ghcr" ? ghcr_plan.immutable_reference : github_release_reference
    end

    def github_release_reference
      "https://github.com/#{repository}/releases/tag/#{manifest.tag}"
    end

    def artifact_evidence
      github_release_plan.artifacts.map do |artifact|
        artifact.slice(:name, :sha256, :size)
      end
    end

    def manifest_digest
      Digest::SHA256.hexdigest(Releases::CanonicalJson.generate(manifest.data))
    end

    def finding(code, message)
      { code: code, severity: "blocker", message: message }
    end
  end
end

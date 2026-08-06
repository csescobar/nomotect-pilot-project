# frozen_string_literal: true

module Distributions
  class ChannelObserver
    HTTP_AVAILABLE = 200
    HTTP_ABSENT = 404
    OBSERVATION_KEYS = %w[status_code digest target_commit target_commitish html_url].freeze

    attr_reader :manifest, :repository, :ghcr_plan

    def initialize(manifest:, repository:, image_digest:)
      @manifest = manifest
      @repository = repository
      @ghcr_plan = GhcrPromotionPlan.new(
        manifest: manifest,
        repository: repository,
        digest: image_digest
      )
    end

    def github_release(observation)
      exact_keys!(observation, %w[release tag], "GitHub observation")
      release = provider_state!(observation.fetch("release"), "release")
      tag = provider_state!(observation.fetch("tag"), "tag")

      return state("github_release", "unavailable", findings: [ finding("remote_state_unavailable") ]) if
        unavailable?(release) || unavailable?(tag)
      return state("github_release", "absent") if absent?(release) && absent?(tag)
      return state("github_release", "partial", findings: [ finding("channel_partial") ]) unless
        available?(release) && available?(tag)

      required_strings!(release, %w[target_commitish html_url], "release")
      required_strings!(tag, %w[target_commit], "tag")
      observed_commit = tag.fetch("target_commit")
      canonical_reference = "https://github.com/#{repository}/releases/tag/#{manifest.tag}"
      compatible = release.fetch("target_commitish") == manifest.commit &&
        observed_commit == manifest.commit &&
        release.fetch("html_url") == canonical_reference

      state(
        "github_release",
        compatible ? "available" : "conflict",
        immutable_reference: compatible ? canonical_reference : release.fetch("html_url"),
        observed_commit: valid_commit(observed_commit),
        findings: compatible ? [] : [ finding("release_conflict") ]
      )
    end

    def ghcr(observation)
      exact_keys!(observation, %w[commit_tag full_tag minor_tag], "GHCR observation")
      commit_tag = provider_state!(observation.fetch("commit_tag"), "commit_tag")
      semantic_tags = %w[full_tag minor_tag].map do |key|
        provider_state!(observation.fetch(key), key)
      end

      return state("ghcr", "unavailable", findings: [ finding("remote_state_unavailable") ]) if
        unavailable?(commit_tag) || semantic_tags.any? { |tag| unavailable?(tag) }

      if semantic_tags.all? { |tag| absent?(tag) }
        required_strings!(commit_tag, %w[digest], "commit_tag") if available?(commit_tag)
        return state("ghcr", "conflict", findings: [ finding("image_source_missing") ]) unless
          available?(commit_tag) && commit_tag.fetch("digest") == ghcr_plan.digest

        return state("ghcr", "absent")
      end

      return state("ghcr", "partial", findings: [ finding("channel_partial") ]) unless
        available?(commit_tag) && semantic_tags.all? { |tag| available?(tag) }

      required_strings!(commit_tag, %w[digest], "commit_tag")
      semantic_tags.each.with_index do |tag, index|
        required_strings!(tag, %w[digest], "semantic_tags[#{index}]")
      end
      digests = [ commit_tag, *semantic_tags ].map { |tag| tag.fetch("digest") }
      compatible = digests.all? { |digest| digest == ghcr_plan.digest }
      state(
        "ghcr",
        compatible ? "available" : "conflict",
        immutable_reference: compatible ? ghcr_plan.immutable_reference : nil,
        observed_commit: compatible ? manifest.commit : nil,
        findings: compatible ? [] : [ finding("image_digest_mismatch") ]
      )
    end

    private

    def state(
      channel,
      status,
      immutable_reference: nil,
      observed_commit: nil,
      findings: []
    )
      ChannelState.new(
        "schema_version" => 1,
        "channel" => channel,
        "repository" => repository,
        "version" => manifest.version,
        "tag" => manifest.tag,
        "status" => status,
        "immutable_reference" => immutable_reference,
        "observed_commit" => observed_commit,
        "findings" => findings
      )
    end

    def provider_state!(value, path)
      raise InvalidObservation, "#{path} must be an object" unless value.is_a?(Hash)

      extra = value.keys - OBSERVATION_KEYS
      raise InvalidObservation, "#{path} has unsupported keys: #{extra.join(', ')}" if extra.any?
      raise InvalidObservation, "#{path} is missing status_code" unless value.key?("status_code")
      raise InvalidObservation, "#{path} status_code must be an integer" unless
        value.fetch("status_code").is_a?(Integer)

      value
    end

    def exact_keys!(value, expected, path)
      raise InvalidObservation, "#{path} must be an object" unless value.is_a?(Hash)

      extra = value.keys - expected
      missing = expected - value.keys
      raise InvalidObservation, "#{path} has unsupported keys: #{extra.join(', ')}" if extra.any?
      raise InvalidObservation, "#{path} is missing keys: #{missing.join(', ')}" if missing.any?
    end

    def required_strings!(value, keys, path)
      keys.each do |key|
        raise InvalidObservation, "#{path}.#{key} must be a non-empty string" unless
          value[key].is_a?(String) && value[key].present?
      end
    end

    def available?(value) = value.fetch("status_code") == HTTP_AVAILABLE
    def absent?(value) = value.fetch("status_code") == HTTP_ABSENT
    def unavailable?(value) = !available?(value) && !absent?(value)

    def valid_commit(value)
      value if value.is_a?(String) && ChannelState::COMMIT.match?(value)
    end

    def finding(code) = { "code" => code, "severity" => "blocker" }

    class InvalidObservation < StandardError; end
  end
end

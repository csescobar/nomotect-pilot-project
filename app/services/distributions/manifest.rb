# frozen_string_literal: true

require "json"

module Distributions
  class Manifest
    SCHEMA_VERSION = 1
    CHANNEL_IDS = %w[ghcr github_release].freeze
    ARTIFACT_IDS = %w[
      application_sbom
      application_starter_tar
      application_starter_zip
      checksums
      compatibility
      container_sbom
      migration_notes
      packaging_manifest
      provenance
      release_notes
      upgrade_notes
    ].freeze
    TOP_LEVEL_KEYS = %w[
      schema_version release repository channels artifacts policy recovery
    ].freeze
    DIGEST = /\A[a-f0-9]{64}\z/
    COMMIT = /\A[a-f0-9]{40}\z/

    attr_reader :data

    def self.load(path)
      new(JSON.parse(File.read(path)))
    rescue JSON::ParserError => error
      raise InvalidManifest, "distribution manifest is not valid JSON: #{error.message}"
    end

    def initialize(data)
      @data = data
      validate!
      deep_freeze(@data)
    end

    def version = data.dig("release", "version")
    def tag = data.dig("release", "tag")
    def commit = data.dig("release", "commit")
    def channels = data.fetch("channels")
    def artifacts = data.fetch("artifacts")

    private

    def validate!
      object!(data, "manifest")
      exact_keys!(data, TOP_LEVEL_KEYS, "manifest")
      const!(data, "schema_version", SCHEMA_VERSION)
      validate_release!
      validate_repository!
      validate_channels!
      validate_artifacts!
      validate_policy!
      validate_recovery!
    rescue KeyError => error
      raise InvalidManifest, "missing required key: #{error.key}"
    rescue ArgumentError => error
      raise InvalidManifest, error.message
    end

    def validate_release!
      release = object!(data.fetch("release"), "release")
      exact_keys!(
        release,
        %w[version tag commit release_metadata_digest compatibility_digest],
        "release"
      )
      version = Platform::Version.new(string!(release, "version")).to_s
      const!(release, "tag", "v#{version}")
      pattern!(release.fetch("commit"), COMMIT, "release.commit")
      pattern!(
        release.fetch("release_metadata_digest"),
        DIGEST,
        "release.release_metadata_digest"
      )
      pattern!(
        release.fetch("compatibility_digest"),
        DIGEST,
        "release.compatibility_digest"
      )
    end

    def validate_repository!
      repository = object!(data.fetch("repository"), "repository")
      exact_keys!(repository, %w[identity source_branch], "repository")
      const!(repository, "identity", "repository_context")
      const!(repository, "source_branch", "main")
    end

    def validate_channels!
      channels = array!(data, "channels")
      ids = channels.map.with_index do |channel, index|
        value = object!(channel, "channels[#{index}]")
        id = string!(value, "id")
        case id
        when "github_release" then validate_github_release!(value)
        when "ghcr" then validate_ghcr!(value)
        else raise InvalidManifest, "unsupported distribution channel: #{id}"
        end
        id
      end
      raise InvalidManifest, "distribution channel ids must be unique" unless ids.uniq == ids
      raise InvalidManifest, "github_release and ghcr channels are required" unless
        ids.sort == CHANNEL_IDS
    end

    def validate_github_release!(channel)
      exact_keys!(channel, %w[id enabled prerelease], "github_release channel")
      const!(channel, "enabled", true)
      boolean!(channel, "prerelease")
    end

    def validate_ghcr!(channel)
      exact_keys!(
        channel,
        %w[id enabled semantic_tags architectures rebuild allow_latest],
        "ghcr channel"
      )
      const!(channel, "enabled", true)
      const!(channel, "rebuild", false)
      const!(channel, "allow_latest", false)
      exact_array!(channel, "semantic_tags", %w[full minor])
      exact_array!(channel, "architectures", %w[linux/amd64 linux/arm64])
    end

    def validate_artifacts!
      artifacts = array!(data, "artifacts")
      artifacts.each { |artifact| string_value!(artifact, "artifact") }
      raise InvalidManifest, "artifact ids must be unique" unless artifacts.uniq == artifacts
      raise InvalidManifest, "the complete release artifact set is required" unless
        artifacts.sort == ARTIFACT_IDS
    end

    def validate_policy!
      policy = object!(data.fetch("policy"), "policy")
      exact_keys!(
        policy,
        %w[approval_environment release_requires_approval overwrite],
        "policy"
      )
      const!(policy, "approval_environment", "release")
      const!(policy, "release_requires_approval", true)
      const!(policy, "overwrite", false)
    end

    def validate_recovery!
      recovery = object!(data.fetch("recovery"), "recovery")
      exact_keys!(recovery, %w[strategy partial_publication], "recovery")
      const!(recovery, "strategy", "resume_forward")
      const!(recovery, "partial_publication", "operator_review")
    end

    def exact_keys!(object, expected, path)
      extra = object.keys - expected
      missing = expected - object.keys
      raise InvalidManifest, "#{path} has unsupported keys: #{extra.join(', ')}" if extra.any?
      raise InvalidManifest, "#{path} is missing keys: #{missing.join(', ')}" if missing.any?
    end

    def object!(value, path)
      raise InvalidManifest, "#{path} must be an object" unless value.is_a?(Hash)

      value
    end

    def array!(object, key)
      value = object.fetch(key)
      raise InvalidManifest, "#{key} must be an array" unless value.is_a?(Array)

      value
    end

    def string!(object, key)
      value = object.fetch(key)
      string_value!(value, key)
      value
    end

    def string_value!(value, path)
      raise InvalidManifest, "#{path} must be a non-empty string" unless
        value.is_a?(String) && value.present?
    end

    def boolean!(object, key)
      value = object.fetch(key)
      raise InvalidManifest, "#{key} must be boolean" unless value == true || value == false
    end

    def const!(object, key, expected)
      return if object.fetch(key) == expected

      raise InvalidManifest, "#{key} must equal #{expected.inspect}"
    end

    def pattern!(value, pattern, path)
      raise InvalidManifest, "#{path} has an invalid format" unless
        value.is_a?(String) && pattern.match?(value)
    end

    def exact_array!(object, key, expected)
      values = array!(object, key)
      raise InvalidManifest, "#{key} must contain #{expected.join(', ')}" unless
        values.uniq == values && values.sort == expected.sort
    end

    def deep_freeze(value)
      value.each { |key, item| deep_freeze(key); deep_freeze(item) } if value.is_a?(Hash)
      value.each { |item| deep_freeze(item) } if value.is_a?(Array)
      value.freeze
    end

    class InvalidManifest < StandardError; end
  end
end

# frozen_string_literal: true

require "json"

module Distributions
  class ChannelState
    SCHEMA_VERSION = 1
    CHANNELS = %w[github_release ghcr].freeze
    STATUSES = %w[absent available conflict partial unavailable].freeze
    TOP_LEVEL_KEYS = %w[
      schema_version channel repository version tag status immutable_reference
      observed_commit findings
    ].freeze
    REPOSITORY = /\A[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+\z/
    COMMIT = /\A[a-f0-9]{40}\z/

    attr_reader :data

    def self.load(path)
      new(JSON.parse(File.read(path)))
    rescue JSON::ParserError => error
      raise InvalidState, "channel state is not valid JSON: #{error.message}"
    end

    def initialize(data)
      @data = data
      validate!
      deep_freeze(@data)
    end

    def channel = data.fetch("channel")
    def repository = data.fetch("repository")
    def version = data.fetch("version")
    def tag = data.fetch("tag")
    def status = data.fetch("status")
    def immutable_reference = data.fetch("immutable_reference")
    def observed_commit = data.fetch("observed_commit")
    def findings = data.fetch("findings")

    private

    def validate!
      object!(data, "channel state")
      exact_keys!(data, TOP_LEVEL_KEYS, "channel state")
      const!(data, "schema_version", SCHEMA_VERSION)
      enum!(data, "channel", CHANNELS)
      pattern!(data.fetch("repository"), REPOSITORY, "repository")
      Platform::Version.new(string!(data, "version"))
      string!(data, "tag")
      enum!(data, "status", STATUSES)
      optional_string!(data.fetch("immutable_reference"), "immutable_reference")
      optional_pattern!(data.fetch("observed_commit"), COMMIT, "observed_commit")
      validate_findings!
    rescue KeyError => error
      raise InvalidState, "missing required key: #{error.key}"
    rescue ArgumentError => error
      raise InvalidState, error.message
    end

    def validate_findings!
      findings = array!(data, "findings")
      findings.each.with_index do |finding, index|
        value = object!(finding, "findings[#{index}]")
        exact_keys!(value, %w[code severity], "findings[#{index}]")
        pattern!(value.fetch("code"), /\A[a-z][a-z0-9_]+\z/, "finding code")
        enum!(value, "severity", %w[warning blocker])
      end
    end

    def exact_keys!(object, expected, path)
      extra = object.keys - expected
      missing = expected - object.keys
      raise InvalidState, "#{path} has unsupported keys: #{extra.join(', ')}" if extra.any?
      raise InvalidState, "#{path} is missing keys: #{missing.join(', ')}" if missing.any?
    end

    def object!(value, path)
      raise InvalidState, "#{path} must be an object" unless value.is_a?(Hash)

      value
    end

    def array!(object, key)
      value = object.fetch(key)
      raise InvalidState, "#{key} must be an array" unless value.is_a?(Array)

      value
    end

    def string!(object, key)
      value = object.fetch(key)
      raise InvalidState, "#{key} must be a non-empty string" unless
        value.is_a?(String) && value.present?

      value
    end

    def optional_string!(value, path)
      return if value.nil?
      return if value.is_a?(String) && value.present?

      raise InvalidState, "#{path} must be null or a non-empty string"
    end

    def enum!(object, key, values)
      raise InvalidState, "#{key} is unsupported" unless values.include?(object.fetch(key))
    end

    def const!(object, key, expected)
      raise InvalidState, "#{key} must equal #{expected.inspect}" unless object.fetch(key) == expected
    end

    def pattern!(value, pattern, path)
      raise InvalidState, "#{path} has an invalid format" unless
        value.is_a?(String) && pattern.match?(value)
    end

    def optional_pattern!(value, pattern, path)
      return if value.nil?

      pattern!(value, pattern, path)
    end

    def deep_freeze(value)
      value.each { |key, item| deep_freeze(key); deep_freeze(item) } if value.is_a?(Hash)
      value.each { |item| deep_freeze(item) } if value.is_a?(Array)
      value.freeze
    end

    class InvalidState < StandardError; end
  end
end

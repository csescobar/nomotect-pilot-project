# frozen_string_literal: true

require "json"

module Upgrades
  class BackupEvidence
    SCHEMA_VERSION = 1
    KINDS = %w[database persistent_files].freeze
    KEYS = %w[schema_version id kind captured_at source provider reference checksum].freeze

    attr_reader :data

    def self.load(path)
      Array(JSON.parse(File.read(path))).map { |record| new(record) }
    rescue JSON::ParserError
      raise InvalidEvidence, "backup evidence is not valid JSON"
    end

    def initialize(data)
      @data = data
      validate!
      deep_freeze(@data)
    end

    def kind = data.fetch("kind")
    def captured_at = Time.iso8601(data.fetch("captured_at"))
    def source = data.fetch("source")

    private

    def validate!
      raise InvalidEvidence, "backup evidence must be an object" unless data.is_a?(Hash)
      raise InvalidEvidence, "backup evidence has unsupported fields" unless (data.keys - KEYS).empty?
      raise InvalidEvidence, "backup evidence is missing fields" unless (KEYS - data.keys).empty?
      raise InvalidEvidence, "unsupported backup evidence schema" unless data["schema_version"] == SCHEMA_VERSION
      raise InvalidEvidence, "unsupported backup kind" unless KINDS.include?(data["kind"])
      %w[id captured_at provider reference].each do |key|
        raise InvalidEvidence, "#{key} must be present" unless data[key].is_a?(String) && data[key].present?
      end
      Time.iso8601(data.fetch("captured_at"))
      source = data.fetch("source")
      raise InvalidEvidence, "source must be an object" unless source.is_a?(Hash)
      required = %w[platform_version database_schema installation_contract]
      raise InvalidEvidence, "source is incomplete" unless (required - source.keys).empty?
      raise InvalidEvidence, "checksum must be a string or null" unless data["checksum"].nil? || data["checksum"].is_a?(String)
    rescue ArgumentError
      raise InvalidEvidence, "captured_at must be an ISO 8601 timestamp"
    end

    def deep_freeze(value)
      value.each { |key, item| deep_freeze(key); deep_freeze(item) } if value.is_a?(Hash)
      value.each { |item| deep_freeze(item) } if value.is_a?(Array)
      value.freeze
    end

    class InvalidEvidence < StandardError; end
  end
end

# frozen_string_literal: true

module OperationalReadiness
  class SupportBundleManifest
    SCHEMA_VERSION = 1
    KEYS = %w[schema_version id generated_at source limits files redactions automated_upload].freeze

    attr_reader :data

    def initialize(data)
      @data = data
      validate!
      deep_freeze(@data)
    end

    def files = data.fetch("files")

    private

    def validate!
      raise InvalidManifest, "support bundle manifest must be an object" unless data.is_a?(Hash)
      raise InvalidManifest, "support bundle manifest has unsupported fields" unless (data.keys - KEYS).empty?
      raise InvalidManifest, "support bundle manifest is incomplete" unless (KEYS - data.keys).empty?
      raise InvalidManifest, "unsupported support bundle manifest schema" unless data["schema_version"] == SCHEMA_VERSION
      raise InvalidManifest, "automated upload must remain disabled" unless data["automated_upload"] == false
      raise InvalidManifest, "support bundle files must be a non-empty array" unless data["files"].is_a?(Array) && data["files"].any?
      raise InvalidManifest, "support bundle redactions must be an object" unless data["redactions"].is_a?(Hash)
      raise InvalidManifest, "support bundle id is invalid" unless data["id"].match?(/\Asupport-\d{8}T\d{6}Z\z/)
      validate_source!
      validate_limits!
      Time.iso8601(data.fetch("generated_at"))
      data.fetch("files").each { |file| validate_file!(file) }
    rescue ArgumentError, KeyError
      raise InvalidManifest, "support bundle manifest contains invalid values"
    end

    def validate_source!
      source = data.fetch("source")
      keys = %w[platform_version source_commit environment]
      raise InvalidManifest, "support bundle source is invalid" unless source.is_a?(Hash) && source.keys.sort == keys.sort
      raise InvalidManifest, "support bundle source is incomplete" unless source.values.all? { |value| value.is_a?(String) && value.present? }
    end

    def validate_limits!
      limits = data.fetch("limits")
      keys = %w[max_entry_bytes max_bundle_bytes]
      raise InvalidManifest, "support bundle limits are invalid" unless limits.is_a?(Hash) && limits.keys.sort == keys.sort
      raise InvalidManifest, "support bundle limits must be positive" unless limits.values.all? { |value| value.is_a?(Integer) && value.positive? }
    end

    def validate_file!(file)
      keys = %w[id path media_type size_bytes checksum]
      raise InvalidManifest, "support bundle file is invalid" unless file.is_a?(Hash) && file.keys.sort == keys.sort
      raise InvalidManifest, "support bundle file id is invalid" unless file.fetch("id").match?(/\A[a-z][a-z0-9_]*\z/)
      raise InvalidManifest, "support bundle file path is invalid" unless file.fetch("path").match?(/\Areports\/[a-z][a-z0-9_]*\.json\z/)
      raise InvalidManifest, "support bundle file identity mismatch" unless file.fetch("path") == "reports/#{file.fetch('id')}.json"
      raise InvalidManifest, "support bundle media type is invalid" unless file.fetch("media_type") == "application/json"
      raise InvalidManifest, "support bundle file size is invalid" unless file.fetch("size_bytes").is_a?(Integer) && file.fetch("size_bytes").positive?
      raise InvalidManifest, "support bundle file checksum is invalid" unless file.fetch("checksum").match?(/\Asha256:[0-9a-f]{64}\z/)
    end

    def deep_freeze(value)
      value.each { |key, item| deep_freeze(key); deep_freeze(item) } if value.is_a?(Hash)
      value.each { |item| deep_freeze(item) } if value.is_a?(Array)
      value.freeze
    end

    class InvalidManifest < StandardError; end
  end
end

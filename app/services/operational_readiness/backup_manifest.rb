# frozen_string_literal: true

require "json"

module OperationalReadiness
  class BackupManifest
    SCHEMA_VERSION = 1
    COMPONENT_KINDS = %w[
      postgresql
      persistent_files
      generated_configuration
      installation_metadata
    ].freeze
    KEYS = %w[schema_version id captured_at source components].freeze
    COMPONENT_KEYS = %w[id kind provider reference checksum size_bytes].freeze
    FORBIDDEN_KEYS = %w[
      credential
      credentials
      password
      secret
      token
      private_key
    ].freeze

    attr_reader :data

    def self.load(path)
      new(JSON.parse(File.read(path)))
    rescue JSON::ParserError
      raise InvalidManifest, "backup manifest is not valid JSON"
    end

    def initialize(data)
      @data = data
      validate!
      deep_freeze(@data)
    end

    def id = data.fetch("id")
    def captured_at = Time.iso8601(data.fetch("captured_at"))
    def source = data.fetch("source")
    def components = data.fetch("components")

    private

    def validate!
      require_object!(data, "backup manifest")
      require_exact_keys!(data, KEYS, "backup manifest")
      raise InvalidManifest, "unsupported backup manifest schema" unless data["schema_version"] == SCHEMA_VERSION
      require_present_string!(data, "id")
      Time.iso8601(data.fetch("captured_at"))
      validate_source!
      validate_components!
      reject_secrets!(data)
    rescue ArgumentError
      raise InvalidManifest, "captured_at must be an ISO 8601 timestamp"
    end

    def validate_source!
      source = data.fetch("source")
      keys = %w[platform_version source_commit database_schema installation_contract]
      require_object!(source, "backup source")
      require_exact_keys!(source, keys, "backup source")
      %w[platform_version source_commit database_schema].each { |key| require_present_string!(source, key) }
      unless source["installation_contract"].is_a?(Integer) && source["installation_contract"].positive?
        raise InvalidManifest, "installation_contract must be a positive integer"
      end
    end

    def validate_components!
      components = data.fetch("components")
      raise InvalidManifest, "components must be an array" unless components.is_a?(Array)

      components.each do |component|
        require_object!(component, "backup component")
        require_exact_keys!(component, COMPONENT_KEYS, "backup component")
        %w[id provider reference checksum].each { |key| require_present_string!(component, key) }
        raise InvalidManifest, "unsupported backup component kind" unless COMPONENT_KINDS.include?(component["kind"])
        unless component["size_bytes"].is_a?(Integer) && component["size_bytes"] >= 0
          raise InvalidManifest, "size_bytes must be a non-negative integer"
        end
      end

      kinds = components.pluck("kind")
      raise InvalidManifest, "backup component kinds must be unique" unless kinds.uniq == kinds
      missing = COMPONENT_KINDS - kinds
      raise InvalidManifest, "backup components are incomplete: #{missing.join(", ")}" if missing.any?
    end

    def reject_secrets!(value)
      case value
      when Hash
        forbidden = value.keys.map(&:to_s) & FORBIDDEN_KEYS
        raise InvalidManifest, "backup manifest contains forbidden secret fields" if forbidden.any?
        value.each_value { |item| reject_secrets!(item) }
      when Array
        value.each { |item| reject_secrets!(item) }
      end
    end

    def require_object!(value, label)
      raise InvalidManifest, "#{label} must be an object" unless value.is_a?(Hash)
    end

    def require_exact_keys!(value, keys, label)
      raise InvalidManifest, "#{label} has unsupported fields" unless (value.keys - keys).empty?
      raise InvalidManifest, "#{label} is missing fields" unless (keys - value.keys).empty?
    end

    def require_present_string!(value, key)
      raise InvalidManifest, "#{key} must be present" unless value[key].is_a?(String) && value[key].present?
    end

    def deep_freeze(value)
      value.each { |key, item| deep_freeze(key); deep_freeze(item) } if value.is_a?(Hash)
      value.each { |item| deep_freeze(item) } if value.is_a?(Array)
      value.freeze
    end

    class InvalidManifest < StandardError; end
  end
end

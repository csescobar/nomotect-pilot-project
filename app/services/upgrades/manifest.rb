# frozen_string_literal: true

require "json"

module Upgrades
  class Manifest
    SCHEMA_VERSION = 1
    TOP_LEVEL_KEYS = %w[schema_version id source target compatibility backup operations deprecations].freeze
    COMPATIBILITY_KEYS = %w[rails ruby postgresql contracts].freeze
    BACKUP_KEYS = %w[required evidence].freeze
    OPERATION_KEYS = %w[id type description reversible requires].freeze
    OPERATION_TYPES = %w[database configuration generated_artifacts operator_action validation].freeze

    attr_reader :data

    def self.load(path)
      new(JSON.parse(File.read(path)))
    rescue JSON::ParserError => error
      raise InvalidManifest, "upgrade manifest is not valid JSON: #{error.message}"
    end

    def initialize(data)
      @data = data
      validate!
      deep_freeze(@data)
    end

    def id = data.fetch("id")
    def source_requirement = data.dig("source", "requirement")
    def target_version = Version.new(data.dig("target", "version"))
    def backup_required? = data.dig("backup", "required")
    def operations = data.fetch("operations")
    def deprecations = data.fetch("deprecations")

    private

    def validate!
      object!(data, "manifest")
      exact_keys!(data, TOP_LEVEL_KEYS, "manifest")
      integer_const!(data, "schema_version", SCHEMA_VERSION)
      string!(data, "id")

      source = object!(data.fetch("source"), "source")
      exact_keys!(source, %w[requirement], "source")
      string!(source, "requirement")
      Version.new("0.0.0").satisfies?(source.fetch("requirement"))

      target = object!(data.fetch("target"), "target")
      exact_keys!(target, %w[version], "target")
      Version.new(string!(target, "version"))

      compatibility = object!(data.fetch("compatibility"), "compatibility")
      exact_keys!(compatibility, COMPATIBILITY_KEYS, "compatibility")
      %w[rails ruby postgresql].each { |key| string!(compatibility, key) }
      contracts = object!(compatibility.fetch("contracts"), "compatibility.contracts")
      raise InvalidManifest, "compatibility.contracts must not be empty" if contracts.empty?
      contracts.each { |name, version| string_value!(name, "contract name"); integer_value!(version, "contract version") }

      backup = object!(data.fetch("backup"), "backup")
      exact_keys!(backup, BACKUP_KEYS, "backup")
      boolean!(backup, "required")
      array!(backup, "evidence").each { |item| string_value!(item, "backup evidence") }

      operations = array!(data, "operations")
      raise InvalidManifest, "operations must not be empty" if operations.empty?
      ids = operations.map.with_index do |operation, index|
        object!(operation, "operations[#{index}]")
        exact_keys!(operation, OPERATION_KEYS, "operations[#{index}]")
        operation_id = string!(operation, "id")
        type = string!(operation, "type")
        raise InvalidManifest, "unsupported operation type: #{type}" unless OPERATION_TYPES.include?(type)
        string!(operation, "description")
        boolean!(operation, "reversible")
        array!(operation, "requires").each { |item| string_value!(item, "operation requirement") }
        operation_id
      end
      raise InvalidManifest, "operation ids must be unique" unless ids.uniq.length == ids.length

      array!(data, "deprecations").each.with_index do |deprecation, index|
        object!(deprecation, "deprecations[#{index}]")
        exact_keys!(deprecation, %w[contract remove_in replacement], "deprecations[#{index}]")
        string!(deprecation, "contract")
        Version.new(string!(deprecation, "remove_in"))
        string!(deprecation, "replacement")
      end
    rescue KeyError => error
      raise InvalidManifest, "missing required key: #{error.key}"
    rescue ArgumentError => error
      raise InvalidManifest, error.message
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
      raise InvalidManifest, "#{path} must be a non-empty string" unless value.is_a?(String) && value.present?
    end

    def integer_const!(object, key, expected)
      value = object.fetch(key)
      raise InvalidManifest, "#{key} must equal #{expected}" unless value == expected
    end

    def integer_value!(value, path)
      raise InvalidManifest, "#{path} must be a positive integer" unless value.is_a?(Integer) && value.positive?
    end

    def boolean!(object, key)
      value = object.fetch(key)
      raise InvalidManifest, "#{key} must be boolean" unless value == true || value == false
    end

    def deep_freeze(value)
      case value
      when Hash
        value.each { |key, nested| deep_freeze(key); deep_freeze(nested) }
      when Array
        value.each { |nested| deep_freeze(nested) }
      end
      value.freeze
    end

    class InvalidManifest < StandardError; end
  end
end

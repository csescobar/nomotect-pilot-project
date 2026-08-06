# frozen_string_literal: true

require "yaml"
require "pathname"

module Extensions
  class Configuration
    SCHEMA_VERSION = 1
    KEYS = %w[id package enabled required].freeze

    attr_reader :data, :path

    def self.load(path)
      new(YAML.safe_load_file(path, aliases: false), path:)
    rescue Psych::Exception => error
      raise InvalidConfiguration, "extension configuration is not valid YAML: #{error.message}"
    end

    def self.load_default(root: Rails.root)
      load_many([
        root.join("config/extensions.yml"),
        root.join("application/config/extensions.yml")
      ])
    end

    def self.load_many(paths)
      existing = paths.map { |path| Pathname(path) }.select(&:file?)
      extensions = existing.flat_map do |path|
        data = YAML.safe_load_file(path, aliases: false)
        new(data, path:).extensions.map(&:dup)
      end
      new(
        { "schema_version" => SCHEMA_VERSION, "extensions" => extensions },
        path: existing
      )
    rescue Psych::Exception => error
      raise InvalidConfiguration, "extension configuration is not valid YAML: #{error.message}"
    end

    def initialize(data, path: nil)
      @data = data
      @path = path
      validate!
      deep_freeze(@data)
    end

    def extensions = data.fetch("extensions")
    def enabled = extensions.select { |item| item.fetch("enabled") }
    def required = enabled.select { |item| item.fetch("required") }

    private

    def validate!
      raise InvalidConfiguration, "configuration must be an object" unless data.is_a?(Hash)
      raise InvalidConfiguration, "configuration has unsupported keys" unless
        (data.keys - %w[schema_version extensions]).empty?
      raise InvalidConfiguration, "configuration is missing keys" unless
        (%w[schema_version extensions] - data.keys).empty?
      raise InvalidConfiguration, "unsupported configuration schema" unless
        data["schema_version"] == SCHEMA_VERSION
      raise InvalidConfiguration, "extensions must be an array" unless data["extensions"].is_a?(Array)

      extensions.each.with_index do |extension, index|
        validate_extension!(extension, index)
      end
      ids = extensions.pluck("id")
      packages = extensions.pluck("package")
      raise InvalidConfiguration, "extension ids must be unique" unless ids.uniq == ids
      raise InvalidConfiguration, "extension packages must be unique" unless packages.uniq == packages
    end

    def validate_extension!(extension, index)
      raise InvalidConfiguration, "extensions[#{index}] must be an object" unless extension.is_a?(Hash)
      raise InvalidConfiguration, "extensions[#{index}] has invalid fields" unless
        extension.keys.sort == KEYS.sort
      unless Manifest::IDENTIFIER.match?(extension["id"].to_s)
        raise InvalidConfiguration, "extensions[#{index}].id is invalid"
      end
      unless Manifest::IDENTIFIER.match?(extension["package"].to_s)
        raise InvalidConfiguration, "extensions[#{index}].package is invalid"
      end
      %w[enabled required].each do |key|
        value = extension[key]
        raise InvalidConfiguration, "extensions[#{index}].#{key} must be boolean" unless
          value == true || value == false
      end
      if extension["required"] && !extension["enabled"]
        raise InvalidConfiguration, "required extensions must be enabled"
      end
    end

    def deep_freeze(value)
      value.each { |key, item| deep_freeze(key); deep_freeze(item) } if value.is_a?(Hash)
      value.each { |item| deep_freeze(item) } if value.is_a?(Array)
      value.freeze
    end

    class InvalidConfiguration < StandardError; end
  end
end

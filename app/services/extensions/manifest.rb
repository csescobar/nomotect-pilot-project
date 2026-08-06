# frozen_string_literal: true

require "yaml"
require "pathname"

module Extensions
  class Manifest
    SCHEMA_VERSION = 1
    CONTRACT_VERSION = 1
    IDENTIFIER = /\A[a-z][a-z0-9]*(?:[.-][a-z0-9]+)*\z/
    ENTRYPOINT = /\A[a-z0-9_]+(?:\/[a-z0-9_]+)*\z/
    TOP_LEVEL_KEYS = %w[
      schema_version extension platform capabilities dependencies components security
    ].freeze

    attr_reader :data, :path

    def self.load(path)
      new(YAML.safe_load_file(path, aliases: false), path:)
    rescue Psych::Exception => error
      raise InvalidManifest, "extension manifest is not valid YAML: #{error.message}"
    end

    def initialize(data, path: nil)
      @data = data
      @path = path
      validate!
      deep_freeze(@data)
    end

    def id = data.dig("extension", "id")
    def version = data.dig("extension", "version")
    def contract_version = data.dig("extension", "contract_version")
    def entrypoint = data.dig("extension", "entrypoint")
    def platform_requirement = data.dig("platform", "requirement")
    def provided_capabilities = data.dig("capabilities", "provides")
    def required_capabilities = data.dig("capabilities", "requires")
    def dependencies = data.fetch("dependencies")
    def components = data.fetch("components")

    private

    def validate!
      object!(data, "manifest")
      exact_keys!(data, TOP_LEVEL_KEYS, "manifest")
      integer_const!(data, "schema_version", SCHEMA_VERSION)
      validate_extension!
      validate_platform!
      validate_capabilities!
      validate_dependencies!
      validate_components!
      validate_security!
    rescue KeyError => error
      raise InvalidManifest, "missing required key: #{error.key}"
    rescue ArgumentError => error
      raise InvalidManifest, error.message
    end

    def validate_extension!
      extension = object!(data.fetch("extension"), "extension")
      exact_keys!(extension, %w[id version contract_version entrypoint], "extension")
      identifier!(extension.fetch("id"), "extension.id")
      Platform::Version.new(string!(extension, "version"))
      positive_integer!(extension.fetch("contract_version"), "extension.contract_version")
      entrypoint = string!(extension, "entrypoint")
      raise InvalidManifest, "extension.entrypoint is invalid" unless ENTRYPOINT.match?(entrypoint)
    end

    def validate_platform!
      platform = object!(data.fetch("platform"), "platform")
      exact_keys!(platform, %w[requirement], "platform")
      requirement!(platform.fetch("requirement"), "platform.requirement")
    end

    def validate_capabilities!
      capabilities = object!(data.fetch("capabilities"), "capabilities")
      exact_keys!(capabilities, %w[provides requires], "capabilities")
      provides = array!(capabilities, "provides")
      requires = array!(capabilities, "requires")
      provides.each.with_index { |item, index| validate_provided_capability!(item, index) }
      requires.each.with_index { |item, index| validate_required_capability!(item, index) }
      unique_ids!(provides, "provided capability")
      unique_ids!(requires, "required capability")
    end

    def validate_provided_capability!(value, index)
      item = object!(value, "capabilities.provides[#{index}]")
      exact_keys!(item, %w[id version], "capabilities.provides[#{index}]")
      identifier!(item.fetch("id"), "provided capability id")
      positive_integer!(item.fetch("version"), "provided capability version")
    end

    def validate_required_capability!(value, index)
      item = object!(value, "capabilities.requires[#{index}]")
      exact_keys!(item, %w[id requirement], "capabilities.requires[#{index}]")
      identifier!(item.fetch("id"), "required capability id")
      requirement!(item.fetch("requirement"), "required capability requirement")
    end

    def validate_dependencies!
      dependencies = array!(data, "dependencies")
      dependencies.each.with_index do |value, index|
        item = object!(value, "dependencies[#{index}]")
        exact_keys!(item, %w[id requirement], "dependencies[#{index}]")
        identifier!(item.fetch("id"), "dependency id")
        requirement!(item.fetch("requirement"), "dependency requirement")
      end
      unique_ids!(dependencies, "dependency")
    end

    def validate_components!
      components = object!(data.fetch("components"), "components")
      exact_keys!(
        components,
        %w[configuration migrations routes assets documentation],
        "components"
      )
      optional_path!(components["configuration"], "components.configuration")
      optional_path!(components["documentation"], "components.documentation")
      validate_migrations!(components.fetch("migrations"))
      validate_namespace_component!(components.fetch("routes"), "routes")
      validate_namespace_component!(components.fetch("assets"), "assets")
    end

    def validate_migrations!(value)
      migrations = object!(value, "components.migrations")
      exact_keys!(migrations, %w[namespace paths], "components.migrations")
      identifier!(migrations.fetch("namespace"), "migration namespace")
      paths = array!(migrations, "paths")
      paths.each { |path| relative_path!(path, "migration path") }
      raise InvalidManifest, "migration paths must be unique" unless paths.uniq == paths
    end

    def validate_namespace_component!(value, name)
      component = object!(value, "components.#{name}")
      exact_keys!(component, %w[namespace], "components.#{name}")
      identifier!(component.fetch("namespace"), "#{name} namespace")
    end

    def validate_security!
      security = object!(data.fetch("security"), "security")
      exact_keys!(security, %w[trust], "security")
      raise InvalidManifest, "security.trust must be trusted_in_process" unless
        security["trust"] == "trusted_in_process"
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
      raise InvalidManifest, "#{key} must be a non-empty string" unless
        value.is_a?(String) && value.present?

      value
    end

    def identifier!(value, path)
      raise InvalidManifest, "#{path} is invalid" unless value.is_a?(String) && IDENTIFIER.match?(value)
    end

    def positive_integer!(value, path)
      raise InvalidManifest, "#{path} must be a positive integer" unless
        value.is_a?(Integer) && value.positive?
    end

    def integer_const!(object, key, expected)
      return if object.fetch(key) == expected

      raise InvalidManifest, "#{key} must be #{expected}"
    end

    def requirement!(value, path)
      raise InvalidManifest, "#{path} must be a non-empty string" unless
        value.is_a?(String) && value.present?

      Gem::Requirement.new(*value.split(",").map(&:strip))
    end

    def optional_path!(value, path)
      return if value.nil?

      relative_path!(value, path)
    end

    def relative_path!(value, path)
      valid = value.is_a?(String) && value.present? &&
        !Pathname(value).absolute? &&
        Pathname(value).each_filename.none? { |part| part == ".." }
      raise InvalidManifest, "#{path} must be a bounded relative path" unless valid
    end

    def unique_ids!(items, label)
      ids = items.pluck("id")
      raise InvalidManifest, "#{label} ids must be unique" unless ids.uniq == ids
    end

    def deep_freeze(value)
      value.each { |key, item| deep_freeze(key); deep_freeze(item) } if value.is_a?(Hash)
      value.each { |item| deep_freeze(item) } if value.is_a?(Array)
      value.freeze
    end

    class InvalidManifest < StandardError; end
  end
end

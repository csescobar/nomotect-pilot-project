# frozen_string_literal: true

require "yaml"

module Epic10
  class ReleaseBaseline
    SCHEMA_VERSION = 1
    TOP_LEVEL_KEYS = %w[schema_version runtimes browsers containers deployments thresholds].freeze
    ENVIRONMENT_KEYS = %w[name version support_level evidence manual_required].freeze
    SUPPORT_LEVELS = %w[certified documented manual].freeze
    THRESHOLD_CATEGORIES = %w[accessibility security privacy performance compatibility reliability ai_readiness].freeze
    METRIC_KEYS = %w[id comparator target unit evidence_required].freeze
    COMPARATORS = %w[lte gte eq].freeze
    REQUIRED_RUNTIMES = %w[ruby rails postgresql].freeze

    attr_reader :data

    def self.load(path)
      new(YAML.safe_load_file(path, aliases: false))
    rescue Psych::Exception => error
      raise InvalidBaseline, "release baseline is not valid YAML: #{error.message}"
    end

    def initialize(data)
      @data = data
      validate!
      deep_freeze(@data)
    end

    def runtime(name) = data.fetch("runtimes").find { |entry| entry.fetch("name") == name }
    def metrics(category) = data.fetch("thresholds").fetch(category)

    private

    def validate!
      object!(data, "release baseline")
      exact_keys!(data, TOP_LEVEL_KEYS, "release baseline")
      invalid!("schema_version must equal #{SCHEMA_VERSION}") unless data.fetch("schema_version") == SCHEMA_VERSION

      %w[runtimes browsers containers deployments].each do |collection|
        validate_environments!(collection, data.fetch(collection))
      end

      runtime_names = data.fetch("runtimes").pluck("name")
      missing = REQUIRED_RUNTIMES - runtime_names
      invalid!("missing required runtimes: #{missing.join(', ')}") if missing.any?

      thresholds = object!(data.fetch("thresholds"), "thresholds")
      exact_keys!(thresholds, THRESHOLD_CATEGORIES, "thresholds")
      thresholds.each { |category, metrics| validate_metrics!(category, metrics) }
    rescue KeyError => error
      invalid!("missing required key: #{error.key}")
    end

    def validate_environments!(name, entries)
      array!(entries, name)
      invalid!("#{name} must not be empty") if entries.empty?
      identifiers = entries.map.with_index do |entry, index|
        path = "#{name}[#{index}]"
        object!(entry, path)
        exact_keys!(entry, ENVIRONMENT_KEYS, path)
        identifier!(entry.fetch("name"), "#{path}.name")
        string!(entry.fetch("version"), "#{path}.version")
        support = enum!(entry.fetch("support_level"), SUPPORT_LEVELS, "#{path}.support_level")
        strings!(entry.fetch("evidence"), "#{path}.evidence", allow_empty: false)
        boolean!(entry.fetch("manual_required"), "#{path}.manual_required")
        invalid!("#{path} manual support must require manual validation") if support == "manual" && !entry.fetch("manual_required")
        entry.fetch("name")
      end
      unique!(identifiers, "#{name} names")
    end

    def validate_metrics!(category, metrics)
      array!(metrics, "thresholds.#{category}")
      invalid!("thresholds.#{category} must not be empty") if metrics.empty?
      ids = metrics.map.with_index do |metric, index|
        path = "thresholds.#{category}[#{index}]"
        object!(metric, path)
        exact_keys!(metric, METRIC_KEYS, path)
        id = identifier!(metric.fetch("id"), "#{path}.id")
        comparator = enum!(metric.fetch("comparator"), COMPARATORS, "#{path}.comparator")
        target = metric.fetch("target")
        invalid!("#{path}.target must be numeric or boolean") unless target.is_a?(Numeric) || [ true, false ].include?(target)
        invalid!("#{path} boolean target requires eq comparator") if [ true, false ].include?(target) && comparator != "eq"
        string!(metric.fetch("unit"), "#{path}.unit")
        strings!(metric.fetch("evidence_required"), "#{path}.evidence_required", allow_empty: false)
        id
      end
      unique!(ids, "#{category} metric ids")
    end

    def exact_keys!(object, expected, path)
      extra = object.keys - expected
      missing = expected - object.keys
      invalid!("#{path} has unsupported keys: #{extra.join(', ')}") if extra.any?
      invalid!("#{path} is missing keys: #{missing.join(', ')}") if missing.any?
    end

    def object!(value, path)
      invalid!("#{path} must be an object") unless value.is_a?(Hash)
      value
    end

    def array!(value, path)
      invalid!("#{path} must be an array") unless value.is_a?(Array)
      value
    end

    def strings!(value, path, allow_empty:)
      array!(value, path)
      invalid!("#{path} must not be empty") if !allow_empty && value.empty?
      value.each { |item| string!(item, path) }
    end

    def string!(value, path)
      invalid!("#{path} must be a non-empty string") unless value.is_a?(String) && !value.strip.empty?
      value
    end

    def identifier!(value, path)
      string!(value, path)
      invalid!("#{path} must use lowercase snake_case") unless /\A[a-z0-9]+(?:_[a-z0-9]+)*\z/.match?(value)
      value
    end

    def enum!(value, values, path)
      invalid!("#{path} must be one of: #{values.join(', ')}") unless values.include?(value)
      value
    end

    def boolean!(value, path)
      invalid!("#{path} must be boolean") unless [ true, false ].include?(value)
      value
    end

    def unique!(values, path)
      invalid!("#{path} must be unique") unless values.uniq.size == values.size
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

    def invalid!(message)
      raise InvalidBaseline, message
    end

    class InvalidBaseline < StandardError; end
  end
end

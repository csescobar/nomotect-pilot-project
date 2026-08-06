# frozen_string_literal: true

require "yaml"

module Epic10
  class RepresentativeApplicationJourney
    THEMES = %w[light dark].freeze
    LOCALES = %w[en pt-BR].freeze
    COLUMN_TYPES = %w[string enum].freeze
    OPERATORS = %w[contains equals not_equals].freeze
    DIRECTIONS = %w[asc desc].freeze
    EVIDENCE = %w[theme_rendering locale_resolution grid_query saved_view export].freeze

    attr_reader :data

    def self.load(path)
      new(YAML.safe_load_file(path, aliases: false))
    rescue Psych::Exception => error
      raise InvalidJourney, "journey YAML is invalid: #{error.message}"
    end

    def initialize(data)
      @data = data
      validate!
      deep_freeze(@data)
    end

    private

    def validate!
      exact_keys!(data, %w[schema_version id themes locales grid evidence], "journey")
      invalid!("schema_version must equal 1") unless data.fetch("schema_version") == 1
      invalid!("journey id must equal design_i18n_grid") unless data.fetch("id") == "design_i18n_grid"
      invalid!("themes must contain only Light and Dark") unless data.fetch("themes") == THEMES

      locales = data.fetch("locales")
      exact_keys!(locales, LOCALES, "locales")
      locales.each { |locale, messages| exact_keys!(messages, %w[title status_label], "locales.#{locale}") }

      grid = data.fetch("grid")
      exact_keys!(grid, %w[columns default_sort saved_view export], "grid")
      columns = grid.fetch("columns")
      invalid!("grid columns must be non-empty") unless columns.is_a?(Array) && columns.any?
      ids = columns.map do |column|
        exact_keys!(column, %w[id type operators], "grid column")
        invalid!("unsupported column type") unless COLUMN_TYPES.include?(column.fetch("type"))
        invalid!("unsupported operator") unless column.fetch("operators").all? { |operator| OPERATORS.include?(operator) }
        column.fetch("id")
      end
      invalid!("grid column ids must be unique") unless ids.uniq.size == ids.size

      sort = grid.fetch("default_sort")
      exact_keys!(sort, %w[column direction], "default sort")
      invalid!("sort references unknown column") unless ids.include?(sort.fetch("column"))
      invalid!("unsupported sort direction") unless DIRECTIONS.include?(sort.fetch("direction"))

      view = grid.fetch("saved_view")
      exact_keys!(view, %w[id filters], "saved view")
      invalid!("saved view filters must be non-empty") unless view.fetch("filters").is_a?(Array) && view.fetch("filters").any?
      view.fetch("filters").each do |filter|
        exact_keys!(filter, %w[column operator value], "saved view filter")
        column = columns.find { |candidate| candidate.fetch("id") == filter.fetch("column") }
        invalid!("filter references unknown column") unless column
        invalid!("filter operator is not allowed by column") unless column.fetch("operators").include?(filter.fetch("operator"))
      end

      export = grid.fetch("export")
      exact_keys!(export, %w[format credential_free], "export")
      invalid!("export format must be csv") unless export.fetch("format") == "csv"
      invalid!("export must be credential free") unless export.fetch("credential_free") == true

      evidence = data.fetch("evidence")
      exact_keys!(evidence, EVIDENCE, "evidence")
      invalid!("every journey evidence item must be required") unless evidence.values.all? { |value| value == "required" }
    rescue KeyError => error
      invalid!("missing required key: #{error.key}")
    end

    def exact_keys!(value, expected, path)
      invalid!("#{path} must be an object") unless value.is_a?(Hash)
      extra = value.keys - expected
      missing = expected - value.keys
      invalid!("#{path} has unsupported keys: #{extra.join(', ')}") if extra.any?
      invalid!("#{path} is missing keys: #{missing.join(', ')}") if missing.any?
    end

    def deep_freeze(value)
      value.each { |key, nested| deep_freeze(key); deep_freeze(nested) } if value.is_a?(Hash)
      value.each { |nested| deep_freeze(nested) } if value.is_a?(Array)
      value.freeze
    end

    def invalid!(message) = raise InvalidJourney, message

    class InvalidJourney < StandardError; end
  end
end

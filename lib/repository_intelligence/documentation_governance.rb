# frozen_string_literal: true

require "date"
require "pathname"
require "yaml"

module RepositoryIntelligence
  class DocumentationGovernance
    ENTRY_KEYS = %w[path owners review_by contracts source_paths].freeze

    def initialize(repository_path:, contracts:, catalog_path: nil, catalog: nil, today: Date.today)
      @repository_path = Pathname(repository_path)
      @contracts = contracts
      @catalog_path = catalog_path && Pathname(catalog_path)
      @catalog = catalog
      @today = today
    end

    def validate
      payload = load_catalog
      return [ "documentation catalog must be an object" ] unless payload.is_a?(Hash)
      return [ "documentation catalog schema_version must be 1" ] unless payload["schema_version"] == 1

      document_entries = payload.fetch("documents")
      return [ "documentation catalog documents must be an array" ] unless document_entries.is_a?(Array)

      findings = validate_schema(document_entries)
      paths = document_entries.filter_map { |entry| entry["path"] if entry.is_a?(Hash) }
      findings << "documentation catalog paths must be unique" unless paths.uniq == paths
      findings
    rescue KeyError => error
      [ "documentation catalog is missing #{error.key}" ]
    rescue Psych::Exception => error
      [ "documentation catalog is invalid YAML: #{error.message}" ]
    end

    private

    attr_reader :repository_path, :contracts, :catalog_path, :catalog, :today

    def load_catalog
      catalog || YAML.safe_load_file(catalog_path, aliases: false)
    end

    def validate_schema(entries)
      entries.each_with_index.flat_map do |entry, index|
        validate_entry(entry, index)
      end
    end

    def validate_entry(entry, index)
      return [ "documentation entry #{index} must be an object" ] unless entry.is_a?(Hash)

      label = entry["path"] || "entry #{index}"
      findings = exact_keys(entry, label)
      return findings if findings.any?

      findings.concat(validate_path(entry.fetch("path"), label))
      findings.concat(validate_owners(entry.fetch("owners"), label))
      findings.concat(validate_review_date(entry.fetch("review_by"), label))
      findings.concat(validate_contracts(entry.fetch("contracts"), label))
      findings.concat(validate_sources(entry.fetch("source_paths"), label))
      findings
    end

    def exact_keys(entry, label)
      extra = entry.keys - ENTRY_KEYS
      missing = ENTRY_KEYS - entry.keys
      findings = []
      findings << "#{label} has unsupported fields: #{extra.join(', ')}" if extra.any?
      findings << "#{label} is missing fields: #{missing.join(', ')}" if missing.any?
      findings
    end

    def validate_path(value, label)
      return [ "#{label} path must be a bounded relative path" ] unless bounded_path?(value)
      return [] if repository_path.join(value).file?

      [ "#{label} documentation file is missing" ]
    end

    def validate_owners(value, label)
      valid = value.is_a?(Array) && value.any? &&
        value.all? { |owner| owner.is_a?(String) && owner.match?(/\A@[a-zA-Z0-9-]+\z/) }
      valid ? [] : [ "#{label} must declare at least one GitHub owner" ]
    end

    def validate_review_date(value, label)
      review_by = Date.iso8601(value.to_s)
      review_by < today ? [ "#{label} documentation review is stale since #{review_by}" ] : []
    rescue Date::Error
      [ "#{label} review_by must be an ISO 8601 date" ]
    end

    def validate_contracts(value, label)
      return [ "#{label} contracts must be a non-empty array" ] unless value.is_a?(Array) && value.any?

      known = contracts.map { |contract| contract.fetch("id") }
      unknown = value - known
      unknown.map { |contract| "#{label} references unknown contract #{contract}" }
    end

    def validate_sources(value, label)
      return [ "#{label} source_paths must be a non-empty array" ] unless value.is_a?(Array) && value.any?

      value.flat_map do |path|
        next [ "#{label} source path must be bounded: #{path}" ] unless bounded_path?(path)
        next [] if repository_path.join(path).file?

        [ "#{label} source path is missing: #{path}" ]
      end
    end

    def bounded_path?(value)
      return false unless value.is_a?(String) && !value.empty?

      path = Pathname(value)
      !path.absolute? && !path.each_filename.include?("..") && path.cleanpath.to_s == value
    end
  end
end

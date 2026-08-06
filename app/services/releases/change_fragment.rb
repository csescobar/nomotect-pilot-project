# frozen_string_literal: true

require "yaml"

module Releases
  class ChangeFragment
    SCHEMA_VERSION = 1
    KEYS = %w[
      schema_version id category summary release_impact contracts migration
      upgrade security privacy accessibility
    ].freeze
    CATEGORIES = %w[
      feature fix security deprecation removal documentation internal
    ].freeze
    RELEASE_IMPACTS = %w[none patch minor major].freeze
    ASSESSMENTS = %w[none reviewed action_required].freeze

    attr_reader :data, :path

    def self.load(path)
      new(YAML.safe_load_file(path, aliases: false), path: path)
    rescue Psych::Exception
      raise InvalidFragment, "change fragment is not valid YAML"
    end

    def initialize(data, path: nil)
      @data = data
      @path = path
      validate!
      deep_freeze(@data)
    end

    def id = data.fetch("id")
    def category = data.fetch("category")
    def summary = data.fetch("summary")
    def release_impact = data.fetch("release_impact")
    def contracts = data.fetch("contracts")

    private

    def validate!
      raise InvalidFragment, "change fragment must be an object" unless data.is_a?(Hash)
      raise InvalidFragment, "change fragment has unsupported fields" unless (data.keys - KEYS).empty?
      raise InvalidFragment, "change fragment is missing fields" unless (KEYS - data.keys).empty?
      raise InvalidFragment, "unsupported change fragment schema" unless data["schema_version"] == SCHEMA_VERSION
      validate_identifier!
      validate_enum!("category", CATEGORIES)
      validate_enum!("release_impact", RELEASE_IMPACTS)
      raise InvalidFragment, "summary must be present" unless data["summary"].is_a?(String) && data["summary"].present?
      validate_contracts!
      validate_action!("migration")
      validate_action!("upgrade")
      %w[security privacy accessibility].each { |name| validate_assessment!(name) }
      validate_release_impact!
    end

    def validate_identifier!
      identifier = data["id"]
      valid = identifier.is_a?(String) && /\A[a-z0-9][a-z0-9-]*\z/.match?(identifier)
      raise InvalidFragment, "id must use lowercase letters numbers and hyphens" unless valid
    end

    def validate_enum!(name, values)
      raise InvalidFragment, "unsupported #{name}" unless values.include?(data[name])
    end

    def validate_contracts!
      contracts = data["contracts"]
      valid = contracts.is_a?(Array) && contracts.all? { |item| item.is_a?(String) && item.present? }
      raise InvalidFragment, "contracts must contain unique names" unless valid && contracts.uniq == contracts
    end

    def validate_action!(name)
      action = data[name]
      valid = action.is_a?(Hash) && action.keys.sort == %w[notes required] &&
        [ true, false ].include?(action["required"]) &&
        (action["notes"].nil? || action["notes"].is_a?(String))
      raise InvalidFragment, "#{name} declaration is invalid" unless valid
      if action["required"] && action["notes"].to_s.strip.empty?
        raise InvalidFragment, "#{name} notes are required when operator action is required"
      end
    end

    def validate_assessment!(name)
      assessment = data[name]
      valid = assessment.is_a?(Hash) && assessment.keys.sort == %w[impact notes] &&
        ASSESSMENTS.include?(assessment["impact"]) &&
        (assessment["notes"].nil? || assessment["notes"].is_a?(String))
      raise InvalidFragment, "#{name} assessment is invalid" unless valid
      if assessment["impact"] == "action_required" && assessment["notes"].to_s.strip.empty?
        raise InvalidFragment, "#{name} notes are required when action is required"
      end
    end

    def validate_release_impact!
      return unless data["release_impact"] == "none"
      return if %w[documentation internal].include?(data["category"])

      raise InvalidFragment, "behavior changes must declare a release impact"
    end

    def deep_freeze(value)
      value.each { |key, item| deep_freeze(key); deep_freeze(item) } if value.is_a?(Hash)
      value.each { |item| deep_freeze(item) } if value.is_a?(Array)
      value.freeze
    end

    class InvalidFragment < StandardError; end
  end
end

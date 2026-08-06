# frozen_string_literal: true

require "json"

module OperationalReadiness
  class RestorePlan
    SCHEMA_VERSION = 1
    KEYS = %w[schema_version id backup_manifest_id target ordered_steps verification].freeze
    STEP_KEYS = %w[id component action requires operator_confirmation].freeze

    attr_reader :data

    def self.load(path)
      new(JSON.parse(File.read(path)))
    rescue JSON::ParserError
      raise InvalidPlan, "restore plan is not valid JSON"
    end

    def initialize(data)
      @data = data
      validate!
      deep_freeze(@data)
    end

    def backup_manifest_id = data.fetch("backup_manifest_id")
    def id = data.fetch("id")
    def target = data.fetch("target")
    def ordered_steps = data.fetch("ordered_steps")
    def verification = data.fetch("verification")

    private

    def validate!
      require_object!(data, "restore plan")
      require_exact_keys!(data, KEYS, "restore plan")
      raise InvalidPlan, "unsupported restore plan schema" unless data["schema_version"] == SCHEMA_VERSION
      %w[id backup_manifest_id].each { |key| require_present_string!(data, key) }
      validate_target!
      validate_steps!
      validate_verification!
      reject_secrets!(data)
    end

    def validate_target!
      target = data.fetch("target")
      keys = %w[environment platform_version]
      require_object!(target, "restore target")
      require_exact_keys!(target, keys, "restore target")
      keys.each { |key| require_present_string!(target, key) }
    end

    def validate_steps!
      steps = data.fetch("ordered_steps")
      raise InvalidPlan, "ordered_steps must be a non-empty array" unless steps.is_a?(Array) && steps.any?

      ids = steps.map do |step|
        require_object!(step, "restore step")
        require_exact_keys!(step, STEP_KEYS, "restore step")
        %w[id component action].each { |key| require_present_string!(step, key) }
        unless BackupManifest::COMPONENT_KINDS.include?(step["component"])
          raise InvalidPlan, "restore step has unsupported component"
        end
        raise InvalidPlan, "restore step requires must be an array" unless step["requires"].is_a?(Array)
        unless [ true, false ].include?(step["operator_confirmation"])
          raise InvalidPlan, "operator_confirmation must be boolean"
        end
        step["id"]
      end

      raise InvalidPlan, "restore step ids must be unique" unless ids.uniq == ids
      steps.each do |step|
        unknown = step.fetch("requires") - ids
        raise InvalidPlan, "restore step has unknown dependencies" if unknown.any?
        if step.fetch("requires").any? { |dependency| ids.index(dependency) >= ids.index(step.fetch("id")) }
          raise InvalidPlan, "restore step dependencies must precede the step"
        end
      end
    end

    def validate_verification!
      verification = data.fetch("verification")
      keys = %w[database_schema installation_contract generated_artifacts application_health]
      require_object!(verification, "restore verification")
      require_exact_keys!(verification, keys, "restore verification")
      unless verification.values.all? { |value| [ true, false ].include?(value) }
        raise InvalidPlan, "restore verification values must be boolean"
      end
    end

    def reject_secrets!(value)
      case value
      when Hash
        forbidden = value.keys.map(&:to_s) & BackupManifest::FORBIDDEN_KEYS
        raise InvalidPlan, "restore plan contains forbidden secret fields" if forbidden.any?
        value.each_value { |item| reject_secrets!(item) }
      when Array
        value.each { |item| reject_secrets!(item) }
      end
    end

    def require_object!(value, label)
      raise InvalidPlan, "#{label} must be an object" unless value.is_a?(Hash)
    end

    def require_exact_keys!(value, keys, label)
      raise InvalidPlan, "#{label} has unsupported fields" unless (value.keys - keys).empty?
      raise InvalidPlan, "#{label} is missing fields" unless (keys - value.keys).empty?
    end

    def require_present_string!(value, key)
      raise InvalidPlan, "#{key} must be present" unless value[key].is_a?(String) && value[key].present?
    end

    def deep_freeze(value)
      value.each { |key, item| deep_freeze(key); deep_freeze(item) } if value.is_a?(Hash)
      value.each { |item| deep_freeze(item) } if value.is_a?(Array)
      value.freeze
    end

    class InvalidPlan < StandardError; end
  end
end

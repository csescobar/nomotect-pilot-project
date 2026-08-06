# frozen_string_literal: true

require "yaml"

module Epic10
  class DomainServicesJourney
    STATES = %w[submitted triaged in_progress resolved].freeze
    EVIDENCE = %w[operation query policy_denial domain_event idempotent_job notification file_checksum audit].freeze

    attr_reader :data

    def self.load(path)
      new(YAML.safe_load_file(path, aliases: false))
    rescue Psych::Exception => error
      raise InvalidJourney, "domain services YAML is invalid: #{error.message}"
    end

    def initialize(data)
      @data = data
      validate!
      deep_freeze(@data)
    end

    private

    def validate!
      exact!(data, %w[schema_version id aggregate states transitions queries services evidence], "journey")
      invalid!("schema_version must equal 1") unless data.fetch("schema_version") == 1
      invalid!("unexpected journey id") unless data.fetch("id") == "domain_services"
      invalid!("states must follow the governed lifecycle") unless data.fetch("states") == STATES

      transitions = data.fetch("transitions")
      invalid!("three lifecycle transitions are required") unless transitions.is_a?(Array) && transitions.size == 3
      transitions.each do |transition|
        exact!(transition, %w[from to operation policy event], "transition")
        invalid!("transition state is unsupported") unless STATES.include?(transition.fetch("from")) && STATES.include?(transition.fetch("to"))
        invalid!("transition must require manage_requests") unless transition.fetch("policy") == "manage_requests"
      end

      invalid!("required queries are missing") unless data.fetch("queries").sort == %w[find_request list_requests]
      services = data.fetch("services")
      exact!(services, %w[background_job notification file audit feature_flag], "services")
      require_true!(services.fetch("background_job"), %w[idempotent retry_safe], "background job")
      require_true!(services.fetch("notification"), %w[tenant_scoped], "notification")
      require_true!(services.fetch("file"), %w[tenant_scoped checksum_required], "file")
      require_true!(services.fetch("audit"), %w[actor_required tenant_required], "audit")
      exact!(services.fetch("feature_flag"), %w[default_enabled], "feature flag")
      invalid!("feature flag must default off") unless services.dig("feature_flag", "default_enabled") == false

      evidence = data.fetch("evidence")
      exact!(evidence, EVIDENCE, "evidence")
      invalid!("all evidence must be required") unless evidence.values.all? { |value| value == "required" }
    rescue KeyError => error
      invalid!("missing required key: #{error.key}")
    end

    def require_true!(value, keys, path)
      exact!(value, keys, path)
      invalid!("#{path} safeguards must be enabled") unless value.values.all?(true)
    end

    def exact!(value, expected, path)
      invalid!("#{path} must be an object") unless value.is_a?(Hash)
      invalid!("#{path} has unsupported keys") unless value.keys.sort == expected.sort
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

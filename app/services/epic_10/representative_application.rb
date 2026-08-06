# frozen_string_literal: true

require "yaml"

module Epic10
  class RepresentativeApplication
    FOUNDATION_KEYS = %w[schema_version id architecture_id tenants actors service_requests dependencies evidence].freeze
    TENANT_KEYS = %w[id name locale theme].freeze
    ACTOR_KEYS = %w[id tenant_id role].freeze
    REQUEST_KEYS = %w[id tenant_id title status assignee_id].freeze
    EVIDENCE_KEYS = %w[deterministic credential_free personal_data source_commit_required].freeze
    ROLES = %w[owner administrator member].freeze
    STATUSES = %w[submitted triaged in_progress resolved].freeze

    attr_reader :architecture, :foundation

    def self.load(architecture_path:, foundation_path:)
      new(
        architecture: YAML.safe_load_file(architecture_path, aliases: false),
        foundation: YAML.safe_load_file(foundation_path, aliases: false)
      )
    rescue Psych::Exception => error
      raise InvalidFoundation, "representative application YAML is invalid: #{error.message}"
    end

    def initialize(architecture:, foundation:)
      @architecture = architecture
      @foundation = foundation
      validate!
      deep_freeze(@architecture)
      deep_freeze(@foundation)
    end

    private

    def validate!
      object!(architecture, "architecture")
      object!(foundation, "foundation")
      exact_keys!(foundation, FOUNDATION_KEYS, "foundation")
      invalid!("schema_version must equal 1") unless foundation.fetch("schema_version") == 1
      invalid!("architecture_id must match architecture") unless foundation.fetch("architecture_id") == architecture.fetch("id")
      invalid!("foundation id must use lowercase snake_case") unless identifier?(foundation.fetch("id"))

      tenants = records!(foundation.fetch("tenants"), TENANT_KEYS, "tenants")
      invalid!("at least two tenants are required") if tenants.size < architecture.fetch("required_tenants")
      unique!(tenants.pluck("id"), "tenant ids")
      tenants.each do |tenant|
        invalid!("unsupported locale") unless architecture.fetch("required_locales").include?(tenant.fetch("locale"))
        invalid!("unsupported theme") unless architecture.fetch("required_themes").include?(tenant.fetch("theme"))
      end
      required_values!(tenants.pluck("locale"), architecture.fetch("required_locales"), "locales")
      required_values!(tenants.pluck("theme"), architecture.fetch("required_themes"), "themes")

      tenant_ids = tenants.pluck("id")
      actors = records!(foundation.fetch("actors"), ACTOR_KEYS, "actors")
      unique!(actors.pluck("id"), "actor ids")
      actors.each do |actor|
        invalid!("actor references unknown tenant") unless tenant_ids.include?(actor.fetch("tenant_id"))
        invalid!("unsupported actor role") unless ROLES.include?(actor.fetch("role"))
      end

      actor_ids = actors.pluck("id")
      requests = records!(foundation.fetch("service_requests"), REQUEST_KEYS, "service_requests")
      unique!(requests.pluck("id"), "service request ids")
      requests.each do |request|
        invalid!("service request references unknown tenant") unless tenant_ids.include?(request.fetch("tenant_id"))
        invalid!("unsupported service request status") unless STATUSES.include?(request.fetch("status"))
        assignee = actors.find { |actor| actor.fetch("id") == request.fetch("assignee_id") }
        invalid!("service request references unknown assignee") unless assignee
        invalid!("cross-tenant assignment is forbidden") unless assignee.fetch("tenant_id") == request.fetch("tenant_id")
      end

      dependencies = strings!(foundation.fetch("dependencies"), "dependencies")
      forbidden = dependencies & architecture.fetch("forbidden_dependencies")
      invalid!("forbidden dependencies: #{forbidden.join(', ')}") if forbidden.any?
      unknown = dependencies - architecture.fetch("public_contracts")
      invalid!("undocumented dependencies: #{unknown.join(', ')}") if unknown.any?

      evidence = foundation.fetch("evidence")
      object!(evidence, "evidence")
      exact_keys!(evidence, EVIDENCE_KEYS, "evidence")
      invalid!("evidence must be deterministic") unless evidence.fetch("deterministic") == true
      invalid!("evidence must be credential free") unless evidence.fetch("credential_free") == true
      invalid!("evidence must not contain personal data") unless evidence.fetch("personal_data") == false
      invalid!("evidence must require source commit") unless evidence.fetch("source_commit_required") == true
    rescue KeyError => error
      invalid!("missing required key: #{error.key}")
    end

    def records!(value, keys, path)
      invalid!("#{path} must be a non-empty array") unless value.is_a?(Array) && value.any?
      value.each_with_index do |record, index|
        object!(record, "#{path}[#{index}]")
        exact_keys!(record, keys, "#{path}[#{index}]")
        record.each_value { |item| invalid!("#{path}[#{index}] values must be non-empty strings") unless item.is_a?(String) && item.present? }
      end
      value
    end

    def strings!(value, path)
      invalid!("#{path} must be a non-empty string array") unless value.is_a?(Array) && value.any? && value.all? { |item| item.is_a?(String) && item.present? }
      unique!(value, path)
      value
    end

    def object!(value, path)
      invalid!("#{path} must be an object") unless value.is_a?(Hash)
    end

    def exact_keys!(value, expected, path)
      extra = value.keys - expected
      missing = expected - value.keys
      invalid!("#{path} has unsupported keys: #{extra.join(', ')}") if extra.any?
      invalid!("#{path} is missing keys: #{missing.join(', ')}") if missing.any?
    end

    def required_values!(actual, required, path)
      missing = required - actual
      invalid!("missing required #{path}: #{missing.join(', ')}") if missing.any?
    end

    def unique!(values, path)
      invalid!("#{path} must be unique") unless values.uniq.size == values.size
    end

    def identifier?(value) = value.is_a?(String) && /\A[a-z0-9]+(?:_[a-z0-9]+)*\z/.match?(value)

    def deep_freeze(value)
      value.each { |key, nested| deep_freeze(key); deep_freeze(nested) } if value.is_a?(Hash)
      value.each { |nested| deep_freeze(nested) } if value.is_a?(Array)
      value.freeze
    end

    def invalid!(message)
      raise InvalidFoundation, message
    end

    class InvalidFoundation < StandardError; end
  end
end

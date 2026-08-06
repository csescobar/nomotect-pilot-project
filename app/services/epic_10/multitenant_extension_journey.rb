# frozen_string_literal: true

require "yaml"

module Epic10
  class MultitenantExtensionJourney
    ROLES = %w[owner administrator member].freeze
    LIFECYCLE = %w[discovered verified loaded ready disabled].freeze
    EVIDENCE = %w[tenant_isolation role_denial community_only extension_registration extension_lifecycle extension_failure_isolation].freeze

    attr_reader :data

    def self.load(path)
      new(YAML.safe_load_file(path, aliases: false))
    rescue Psych::Exception => error
      raise InvalidJourney, "multi-tenant extension YAML is invalid: #{error.message}"
    end

    def initialize(data)
      @data = data
      validate!
      deep_freeze(@data)
    end

    private

    def validate!
      exact!(data, %w[schema_version id tenants roles permissions community extension evidence], "journey")
      invalid!("schema_version must equal 1") unless data.fetch("schema_version") == 1
      invalid!("unexpected journey id") unless data.fetch("id") == "multitenant_extension"

      tenants = data.fetch("tenants")
      exact!(tenants, %w[minimum cross_tenant_access], "tenants")
      invalid!("at least two tenants are required") unless tenants.fetch("minimum") >= 2
      invalid!("cross-tenant access must be denied") unless tenants.fetch("cross_tenant_access") == "denied"
      invalid!("roles must match platform roles") unless data.fetch("roles") == ROLES

      permissions = data.fetch("permissions")
      exact!(permissions, ROLES, "permissions")
      invalid!("member permissions are overprivileged") unless permissions.fetch("member") == %w[read_requests]
      invalid!("administrators may not manage members") if permissions.fetch("administrator").include?("manage_members")

      community = data.fetch("community")
      exact!(community, %w[operates_without_extensions essential_capabilities_available], "community")
      invalid!("community operation must remain complete") unless community.values.all?(true)

      extension = data.fetch("extension")
      exact!(extension, %w[id registered trusted tenant_scoped lifecycle failure_mode may_disable_community], "extension")
      %w[registered trusted tenant_scoped].each { |key| invalid!("extension #{key} must be true") unless extension.fetch(key) == true }
      invalid!("extension lifecycle is incomplete") unless extension.fetch("lifecycle") == LIFECYCLE
      invalid!("extension failures must be isolated") unless extension.fetch("failure_mode") == "isolated"
      invalid!("extension may not disable community") unless extension.fetch("may_disable_community") == false

      evidence = data.fetch("evidence")
      exact!(evidence, EVIDENCE, "evidence")
      invalid!("all evidence must be required") unless evidence.values.all? { |value| value == "required" }
    rescue KeyError => error
      invalid!("missing required key: #{error.key}")
    end

    def exact!(value, expected, path)
      invalid!("#{path} must be an object") unless value.is_a?(Hash)
      invalid!("#{path} has unsupported or missing keys") unless value.keys.sort == expected.sort
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

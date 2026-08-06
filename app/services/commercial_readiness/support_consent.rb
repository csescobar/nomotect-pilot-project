# frozen_string_literal: true

module CommercialReadiness
  class SupportConsent
    SCHEMA_VERSION = 1
    SCOPES = %w[diagnostics operational_health redacted_configuration].freeze
    FIELDS = %w[schema_version support_id scopes granted_at expires_at revoked_at].freeze

    attr_reader :data

    def self.grant(support_id:, scopes:, expires_at:, granted_at: Time.current)
      new(
        "schema_version" => SCHEMA_VERSION,
        "support_id" => support_id,
        "scopes" => scopes.map(&:to_s).uniq.sort,
        "granted_at" => granted_at.utc.iso8601,
        "expires_at" => expires_at.utc.iso8601,
        "revoked_at" => nil
      )
    end

    def initialize(data)
      @data = data
      validate!
      @data = data.freeze
    end

    def support_id = data.fetch("support_id")
    def scopes = data.fetch("scopes")
    def revoked? = data.fetch("revoked_at").present?

    def active?(at: Time.current)
      !revoked? && at >= Time.iso8601(data.fetch("granted_at")) && at < Time.iso8601(data.fetch("expires_at"))
    end

    def allows?(scope, at: Time.current)
      active?(at:) && scopes.include?(scope.to_s)
    end

    def revoke(at: Time.current)
      self.class.new(data.merge("revoked_at" => at.utc.iso8601))
    end

    private

    def validate!
      valid_fields = data.is_a?(Hash) && data.keys.sort == FIELDS.sort
      raise InvalidConsent, "support consent fields are invalid" unless valid_fields
      raise InvalidConsent, "unsupported support consent schema" unless data["schema_version"] == SCHEMA_VERSION
      valid_support_id = SupportIdentity::IDENTIFIER_PATTERN.match?(data["support_id"].to_s)
      raise InvalidConsent, "support identifier must be an opaque UUID" unless valid_support_id

      valid_scopes = data["scopes"].is_a?(Array) && data["scopes"].any? && (data["scopes"] - SCOPES).empty?
      raise InvalidConsent, "support consent scopes are invalid" unless valid_scopes

      granted_at = Time.iso8601(data.fetch("granted_at"))
      expires_at = Time.iso8601(data.fetch("expires_at"))
      raise InvalidConsent, "support consent must expire after it is granted" unless expires_at > granted_at
      revoked_before_grant = data["revoked_at"] && Time.iso8601(data["revoked_at"]) < granted_at
      raise InvalidConsent, "revocation cannot precede consent" if revoked_before_grant
    rescue ArgumentError, TypeError
      raise InvalidConsent, "support consent timestamps are invalid"
    end

    class InvalidConsent < StandardError; end
  end
end

# frozen_string_literal: true

require "securerandom"

module CommercialReadiness
  class SupportIdentity
    SCHEMA_VERSION = 1
    IDENTIFIER_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    FIELDS = %w[schema_version installation_id support_id customer_id rotated_at].freeze

    attr_reader :data

    def self.create(identifier_generator: -> { SecureRandom.uuid })
      new(
        "schema_version" => SCHEMA_VERSION,
        "installation_id" => identifier_generator.call,
        "support_id" => nil,
        "customer_id" => nil,
        "rotated_at" => nil
      )
    end

    def initialize(data)
      @data = data
      validate!
      @data = data.freeze
    end

    def installation_id = data.fetch("installation_id")
    def support_id = data.fetch("support_id")
    def customer_id = data.fetch("customer_id")
    def support_enabled? = support_id.present?

    def enable_support(customer_id: nil, identifier_generator: -> { SecureRandom.uuid })
      replace(
        "support_id" => identifier_generator.call,
        "customer_id" => customer_id,
        "rotated_at" => nil
      )
    end

    def rotate_support(at: Time.current, identifier_generator: -> { SecureRandom.uuid })
      raise InvalidIdentity, "support identity is not enabled" unless support_enabled?

      replace("support_id" => identifier_generator.call, "rotated_at" => at.utc.iso8601)
    end

    def disable_support
      replace("support_id" => nil, "customer_id" => nil, "rotated_at" => nil)
    end

    def as_json(*) = data

    private

    def replace(values)
      self.class.new(data.merge(values))
    end

    def validate!
      raise InvalidIdentity, "identity fields are invalid" unless data.is_a?(Hash) && data.keys.sort == FIELDS.sort
      raise InvalidIdentity, "unsupported identity schema" unless data["schema_version"] == SCHEMA_VERSION
      validate_identifier!("installation_id", required: true)
      validate_identifier!("support_id")
      validate_identifier!("customer_id")
      raise InvalidIdentity, "customer identity requires support consent" if customer_id.present? && support_id.blank?
      raise InvalidIdentity, "rotation timestamp requires support identity" if data["rotated_at"].present? && support_id.blank?
    end

    def validate_identifier!(field, required: false)
      value = data[field]
      return if value.nil? && !required

      raise InvalidIdentity, "#{field} must be an opaque UUID" unless value.is_a?(String) && IDENTIFIER_PATTERN.match?(value)
    end

    class InvalidIdentity < StandardError; end
  end
end

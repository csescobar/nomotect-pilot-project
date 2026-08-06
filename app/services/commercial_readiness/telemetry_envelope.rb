# frozen_string_literal: true

module CommercialReadiness
  class TelemetryEnvelope
    ALLOWED_ATTRIBUTES = {
      "capability_usage" => %w[capability result],
      "operational_health" => %w[category status duration_ms]
    }.freeze

    def self.build(policy:, category:, attributes:, collected_at: Time.current)
      category = category.to_s
      return unless policy.allows?(category)

      allowed = ALLOWED_ATTRIBUTES.fetch(category)
      normalized = attributes.stringify_keys
      redacted = normalized.keys - allowed

      {
        "schema_version" => 1,
        "category" => category,
        "collected_at" => collected_at.utc.iso8601,
        "attributes" => normalized.slice(*allowed),
        "redacted_fields" => redacted.sort
      }.freeze
    end
  end
end

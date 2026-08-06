# frozen_string_literal: true

module CommercialReadiness
  class SupportSharePlan
    ARTIFACT_SCOPES = {
      "support_bundle" => "diagnostics",
      "health_snapshot" => "operational_health",
      "redacted_configuration" => "redacted_configuration"
    }.freeze

    Result = Data.define(:support_id, :artifacts, :requires_operator_upload)

    def self.build(identity:, consent:, requested_artifacts:, at: Time.current)
      raise ConsentMismatch, "support relationship is not enabled" unless identity.support_enabled?
      raise ConsentMismatch, "consent does not match support identity" unless consent.support_id == identity.support_id

      artifacts = requested_artifacts.map(&:to_s).select do |artifact|
        scope = ARTIFACT_SCOPES[artifact]
        scope && consent.allows?(scope, at:)
      end.uniq.sort

      Result.new(support_id: identity.support_id, artifacts:, requires_operator_upload: true)
    end

    class ConsentMismatch < StandardError; end
  end
end

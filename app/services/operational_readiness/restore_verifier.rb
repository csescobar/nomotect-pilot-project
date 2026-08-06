# frozen_string_literal: true

module OperationalReadiness
  class RestoreVerifier
    CHECKS = %w[database_schema installation_contract generated_artifacts application_health].freeze

    def initialize(manifest:, plan:, execution:, checks:, clock: -> { Time.current.utc })
      @manifest = manifest
      @plan = plan
      @execution = execution
      @checks = checks
      @clock = clock
    end

    def verify!
      raise VerificationFailed, "restore execution is incomplete" unless execution.fetch("status") == "completed"

      results = CHECKS.to_h do |name|
        check = checks.fetch(name) { raise VerificationFailed, "required restore verification is unavailable" }
        [ name, !!check.call ]
      end
      failed = plan.verification.select { |name, required| required && !results.fetch(name) }.keys
      raise VerificationFailed, "required restore verification failed" if failed.any?

      {
        "schema_version" => 1,
        "backup_manifest_id" => manifest.id,
        "restore_plan_id" => plan.id,
        "status" => "certified",
        "verified_at" => clock.call.iso8601,
        "checks" => results
      }
    end

    private

    attr_reader :manifest, :plan, :execution, :checks, :clock

    class VerificationFailed < StandardError; end
  end
end

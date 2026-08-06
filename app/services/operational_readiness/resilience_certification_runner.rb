# frozen_string_literal: true

module OperationalReadiness
  class ResilienceCertificationRunner
    def initialize(registry:, policy:, source_commit:, redactor: DiagnosticRedactor.new, clock: -> { Time.current.utc })
      @registry, @policy, @source_commit, @redactor, @clock = registry, policy, source_commit, redactor, clock
    end

    def call
      raise PolicyNotReady, "disaster recovery policy is not ready" unless policy.readiness.fetch("ready")

      started_at = clock.call
      results = registry.all.map { |scenario| execute(scenario) }
      summary = %w[passed failed blocked].index_with { |status| results.count { |result| result.fetch("status") == status } }
      {
        "schema_version" => 1,
        "source_commit" => source_commit,
        "started_at" => started_at.iso8601,
        "completed_at" => clock.call.iso8601,
        "status" => summary.fetch("failed").zero? && summary.fetch("blocked").zero? ? "certified" : "failed",
        "summary" => summary,
        "scenarios" => results
      }
    end

    private

    attr_reader :registry, :policy, :source_commit, :redactor, :clock

    def execute(scenario)
      result = scenario.callable.call
      redactor.redact(result.merge("id" => scenario.id)).value
    rescue StandardError
      { "id" => scenario.id, "status" => "failed", "code" => "scenario_execution_failed", "evidence" => {} }
    end

    class PolicyNotReady < StandardError; end
  end
end

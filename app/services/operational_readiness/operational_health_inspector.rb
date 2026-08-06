# frozen_string_literal: true

require "timeout"

module OperationalReadiness
  class OperationalHealthInspector
    DEFAULT_TIMEOUT = 2.seconds

    def initialize(registry:, timeout: DEFAULT_TIMEOUT, redactor: DiagnosticRedactor.new,
      clock: -> { Time.current.utc }, monotonic_clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
      @registry, @timeout, @redactor, @clock, @monotonic_clock = registry, timeout, redactor, clock, monotonic_clock
    end

    def call
      signals = registry.all.map { |provider| inspect_provider(provider) }
      status = aggregate(signals)
      counts = HealthSignal::STATUSES.index_with { |value| signals.count { |signal| signal.status == value } }
      {
        "schema_version" => 1,
        "observed_at" => clock.call.iso8601,
        "status" => status,
        "summary" => counts,
        "signals" => signals.map(&:data)
      }
    end

    private

    attr_reader :registry, :timeout, :redactor, :clock, :monotonic_clock

    def inspect_provider(provider)
      started = monotonic_clock.call
      result = Timeout.timeout(timeout) { provider.callable.call }
      details = redactor.redact(result.fetch("details", {})).value
      signal(provider, result.fetch("status"), result.fetch("code"), details, result.fetch("operator_actions", []), started)
    rescue Timeout::Error
      signal(provider, "unknown", "health_provider_timeout", {}, [ "Inspect the provider timeout." ], started)
    rescue StandardError
      signal(provider, "unknown", "health_provider_failed", {}, [ "Inspect the provider failure." ], started)
    end

    def signal(provider, status, code, details, actions, started)
      HealthSignal.new(
        "id" => provider.id,
        "category" => provider.category,
        "required" => provider.required,
        "status" => status,
        "code" => code,
        "observed_at" => clock.call.iso8601,
        "duration_ms" => ((monotonic_clock.call - started) * 1000).round.clamp(0, 2_147_483_647),
        "details" => details,
        "operator_actions" => actions
      )
    end

    def aggregate(signals)
      return "unhealthy" if signals.any? { |signal| signal.required? && signal.status == "unhealthy" }
      return "degraded" if signals.any? { |signal| signal.status != "healthy" }

      "healthy"
    end
  end
end

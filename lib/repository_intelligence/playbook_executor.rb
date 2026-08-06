# frozen_string_literal: true

require "securerandom"
require "timeout"

module RepositoryIntelligence
  class PlaybookExecutor
    Execution = Data.define(:id, :playbook_id, :status, :started_at, :completed_at, :inputs, :steps, :evidence)
    StepResult = Data.define(:id, :operation, :status, :attempts, :duration_ms, :output, :error)

    OPERATIONS = {
      "repository.search" => ->(api, args) { api.search(**symbolize(args)) },
      "repository.describe" => ->(api, args) { api.describe_module(args.fetch("id")) },
      "repository.impact" => ->(api, args) { api.impact_analysis(args.fetch("id"), depth: args.fetch("depth", 2)) },
      "repository.dependency_path" => lambda { |api, args|
        api.dependency_path(from: args.fetch("from"), to: args.fetch("to"), max_depth: args.fetch("max_depth", 6))
      },
      "repository.contract" => ->(api, args) { api.contract(args.fetch("id")) },
      "repository.playbook" => ->(api, args) { api.playbook(args.fetch("id")) },
      "repository.invariants" => ->(api, args) { api.invariants(kind: args["kind"]) },
      "repository.statistics" => ->(api, _args) { api.statistics },
      "repository.validate" => ->(api, _args) { api.validate! },
      "repository.readiness" => ->(api, _args) { api.readiness },
      "repository.generate" => ->(api, _args) { serialize_generation(api.generate!) }
    }.freeze

    def self.symbolize(value)
      value.to_h.transform_keys(&:to_sym)
    end

    def self.serialize_generation(result)
      { files: result.files.keys, quality: result.quality }
    end

    def initialize(api: RepositoryIntelligence, clock: -> { Time.now.utc }, monotonic_clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
      @api = api
      @clock = clock
      @monotonic_clock = monotonic_clock
    end

    def validate(playbook)
      findings = []
      findings << "playbook id is required" if playbook["id"].to_s.empty?
      findings << "playbook steps must be an array" unless playbook["steps"].is_a?(Array)
      Array(playbook["steps"]).each_with_index do |step, index|
        findings << "step #{index + 1} must be an object" unless step.is_a?(Hash)
        next unless step.is_a?(Hash)

        findings << "step #{index + 1} id is required" if step["id"].to_s.empty?
        findings << "step #{index + 1} uses unknown operation #{step['tool']}" unless OPERATIONS.key?(step["tool"])
      end
      findings
    end

    def execute(playbook, inputs: {})
      findings = validate(playbook)
      raise ArgumentError, findings.join(", ") unless findings.empty?

      execution_id = SecureRandom.uuid
      started_at = clock.call
      api.publish(:playbook_started, execution_id:, playbook_id: playbook.fetch("id"), inputs:)
      context = { "inputs" => inputs, "steps" => {} }
      results = []
      status = "completed"

      Array(playbook.fetch("steps")).each do |step|
        result = execute_step(step, context:, execution_id:)
        results << result
        context["steps"][step.fetch("id")] = result.output
        next unless result.status == "failed"

        status = "failed"
        break if step.fetch("on_failure", playbook.fetch("on_failure", "stop")) == "stop"
      end

      completed_at = clock.call
      evidence = {
        successful_steps: results.count { |result| result.status == "completed" },
        failed_steps: results.count { |result| result.status == "failed" },
        completion_gate: evaluate_gate(playbook, results)
      }
      status = "failed" unless evidence.fetch(:completion_gate)
      event = status == "completed" ? :playbook_completed : :playbook_failed
      api.publish(event, execution_id:, playbook_id: playbook.fetch("id"), evidence:)
      Execution.new(
        id: execution_id, playbook_id: playbook.fetch("id"), status:, started_at:, completed_at:,
        inputs:, steps: results, evidence:
      )
    end

    private

    attr_reader :api, :clock, :monotonic_clock

    def execute_step(step, context:, execution_id:)
      operation = step.fetch("tool")
      attempts = 0
      maximum_attempts = step.fetch("retry", 0).to_i + 1
      started = monotonic_clock.call
      api.publish(:playbook_step_started, execution_id:, step_id: step.fetch("id"), operation:)

      begin
        attempts += 1
        arguments = interpolate(step.fetch("args", {}), context)
        output = Timeout.timeout(step.fetch("timeout_seconds", 10).to_f) { OPERATIONS.fetch(operation).call(api, arguments) }
        result = StepResult.new(
          id: step.fetch("id"), operation:, status: "completed", attempts:,
          duration_ms: elapsed_ms(started), output:, error: nil
        )
        api.publish(:playbook_step_completed, execution_id:, step_id: result.id, operation:, attempts:)
        result
      rescue StandardError => error
        retry if attempts < maximum_attempts

        result = StepResult.new(
          id: step.fetch("id"), operation:, status: "failed", attempts:,
          duration_ms: elapsed_ms(started), output: nil, error: error.message
        )
        api.publish(:playbook_step_failed, execution_id:, step_id: result.id, operation:, error: error.message)
        result
      end
    end

    def interpolate(value, context)
      case value
      when Hash then value.to_h { |key, item| [ key, interpolate(item, context) ] }
      when Array then value.map { |item| interpolate(item, context) }
      when String then value.gsub(/\{\{([^}]+)\}\}/) { dig_context(context, Regexp.last_match(1).strip).to_s }
      else value
      end
    end

    def dig_context(context, path)
      path.split(".").reduce(context) { |memo, key| memo.fetch(key) }
    end

    def evaluate_gate(playbook, results)
      gates = Array(playbook["completion_gate"])
      return results.none? { |result| result.status == "failed" } if gates.empty?

      gates.all? do |gate|
        case gate
        when "all_steps_pass" then results.all? { |result| result.status == "completed" }
        when "validation_passes"
          result = results.reverse.find { |item| item.operation == "repository.validate" }
          result&.status == "completed" && Array(result.output).empty?
        when "repository_ready"
          result = results.reverse.find { |item| item.operation == "repository.readiness" }
          result&.status == "completed" && readiness_status(result.output) == "ready"
        else false
        end
      end
    end

    def readiness_status(output)
      return unless output.respond_to?(:fetch)

      output.fetch(:status) { output.fetch("status", nil) }
    end

    def elapsed_ms(started)
      ((monotonic_clock.call - started) * 1_000).round(2)
    end
  end
end

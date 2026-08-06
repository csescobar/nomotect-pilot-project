# frozen_string_literal: true

module RepositoryIntelligence
  module Health
  end

  Finding = Data.define(:validator, :category, :severity, :message, :evidence, :remediation)
  ValidationResult = Data.define(:id, :category, :status, :score, :findings, :evidence)

  class ValidatorRegistry
    def initialize
      @validators = {}
    end

    def register(id, category:, &block)
      raise ArgumentError, "validator block is required" unless block

      validators[id.to_sym] = { category: category.to_sym, callable: block }
      self
    end

    def ids
      validators.keys.sort
    end

    def run(id = nil)
      selected = id ? { id.to_sym => validators.fetch(id.to_sym) } : validators
      selected.sort.map { |name, definition| execute(name, definition) }
    end

    private

    attr_reader :validators

    def execute(id, definition)
      payload = definition.fetch(:callable).call
      findings = Array(payload[:findings]).map do |finding|
        finding.is_a?(Finding) ? finding : Finding.new(
          validator: id.to_s, category: definition.fetch(:category).to_s,
          severity: finding.fetch(:severity, "warning"), message: finding.fetch(:message),
          evidence: finding[:evidence], remediation: finding[:remediation]
        )
      end
      score = payload.fetch(:score, score_for(findings)).to_i.clamp(0, 100)
      ValidationResult.new(
        id: id.to_s, category: definition.fetch(:category).to_s,
        status: status_for(score, findings), score:, findings:, evidence: payload[:evidence]
      )
    rescue StandardError => error
      finding = Finding.new(
        validator: id.to_s, category: definition.fetch(:category).to_s, severity: "error",
        message: error.message, evidence: nil, remediation: "Inspect the validator failure and rerun repository health."
      )
      ValidationResult.new(id: id.to_s, category: definition.fetch(:category).to_s, status: "failed", score: 0,
                           findings: [ finding ], evidence: nil)
    end

    def score_for(findings)
      penalties = findings.sum { |finding| { "info" => 1, "warning" => 10, "error" => 30 }.fetch(finding.severity, 10) }
      100 - penalties
    end

    def status_for(score, findings)
      return "failed" if findings.any? { |finding| finding.severity == "error" } || score < 70
      return "warning" if findings.any? || score < 90

      "passed"
    end
  end

  class HealthAggregator
    def initialize(results, generated_at: Time.now.utc)
      @results = results
      @generated_at = generated_at
    end

    def to_h
      grouped = results.group_by(&:category)
      categories = grouped.sort.to_h do |category, values|
        [ category, { score: average(values.map(&:score)), status: category_status(values), validators: values.map(&:id) } ]
      end
      score = average(results.map(&:score))
      {
        schema_version: "1.0", generated_at: generated_at.iso8601, score:,
        status: overall_status(score, results), categories:,
        validators: results.map { |result| serialize_result(result) },
        findings: results.flat_map(&:findings).map(&:to_h), remediation: remediation(results)
      }
    end

    private

    attr_reader :results, :generated_at

    def average(values)
      values.empty? ? 100 : (values.sum.to_f / values.size).round
    end

    def category_status(values)
      return "failed" if values.any? { |value| value.status == "failed" }
      return "warning" if values.any? { |value| value.status == "warning" }

      "passed"
    end

    def overall_status(score, values)
      return "unhealthy" if values.any? { |value| value.status == "failed" } || score < 70
      return "degraded" if values.any? { |value| value.status == "warning" } || score < 90

      "healthy"
    end

    def serialize_result(result)
      result.to_h.merge(findings: result.findings.map(&:to_h))
    end

    def remediation(values)
      values.flat_map(&:findings).filter_map(&:remediation).uniq.sort
    end
  end
end

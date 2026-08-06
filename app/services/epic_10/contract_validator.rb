# frozen_string_literal: true

require "time"

module Epic10
  class ContractValidator
    SCHEMA_VERSION = 1
    SEVERITIES = %w[critical high medium low].freeze
    FINDING_STATUSES = %w[open resolved accepted].freeze
    CERTIFICATION_STATUSES = %w[passed failed blocked].freeze
    PHASE_STATUSES = %w[pending in_progress complete blocked].freeze

    PLAN_KEYS = %w[schema_version id owner phases].freeze
    PLAN_PHASE_KEYS = %w[id objective owner evidence_required].freeze
    FINDING_KEYS = %w[schema_version id phase severity status summary owner remediation evidence waiver].freeze
    WAIVER_KEYS = %w[owner rationale approved_by approved_at expires_at].freeze
    CERTIFICATION_KEYS = %w[schema_version id commit status checked_at phases findings].freeze
    CERTIFICATION_PHASE_KEYS = %w[id status evidence].freeze
    CERTIFICATION_FINDING_KEYS = %w[id severity status].freeze

    def self.validate_plan!(data) = new.validate_plan!(data)
    def self.validate_finding!(data) = new.validate_finding!(data)
    def self.validate_certification!(data) = new.validate_certification!(data)

    def validate_plan!(data)
      object!(data, "validation plan")
      exact_keys!(data, PLAN_KEYS, "validation plan")
      schema!(data)
      identifier!(data.fetch("id"), "plan id")
      string!(data.fetch("owner"), "plan owner")
      phases = nonempty_array!(data.fetch("phases"), "phases")
      phase_ids = phases.map.with_index do |phase, index|
        object!(phase, "phases[#{index}]")
        exact_keys!(phase, PLAN_PHASE_KEYS, "phases[#{index}]")
        id = identifier!(phase.fetch("id"), "phase id")
        string!(phase.fetch("objective"), "phase objective")
        string!(phase.fetch("owner"), "phase owner")
        strings!(phase.fetch("evidence_required"), "phase evidence")
        id
      end
      unique!(phase_ids, "phase ids")
      freeze_contract(data)
    rescue KeyError => error
      invalid!("missing required key: #{error.key}")
    end

    def validate_finding!(data)
      object!(data, "finding")
      exact_keys!(data, FINDING_KEYS, "finding")
      schema!(data)
      identifier!(data.fetch("id"), "finding id")
      identifier!(data.fetch("phase"), "finding phase")
      enum!(data.fetch("severity"), SEVERITIES, "severity")
      status = enum!(data.fetch("status"), FINDING_STATUSES, "status")
      string!(data.fetch("summary"), "summary")
      string!(data.fetch("owner"), "owner")
      string!(data.fetch("remediation"), "remediation")
      strings!(data.fetch("evidence"), "evidence")
      validate_waiver!(data.fetch("waiver"), status:, severity: data.fetch("severity"))
      freeze_contract(data)
    rescue KeyError => error
      invalid!("missing required key: #{error.key}")
    end

    def validate_certification!(data)
      object!(data, "certification")
      exact_keys!(data, CERTIFICATION_KEYS, "certification")
      schema!(data)
      identifier!(data.fetch("id"), "certification id")
      invalid!("commit must be a full Git SHA") unless /\A[0-9a-f]{40}\z/.match?(data.fetch("commit"))
      status = enum!(data.fetch("status"), CERTIFICATION_STATUSES, "certification status")
      timestamp!(data.fetch("checked_at"), "checked_at")

      phases = nonempty_array!(data.fetch("phases"), "phases")
      phase_ids = phases.map.with_index do |phase, index|
        object!(phase, "phases[#{index}]")
        exact_keys!(phase, CERTIFICATION_PHASE_KEYS, "phases[#{index}]")
        id = identifier!(phase.fetch("id"), "phase id")
        enum!(phase.fetch("status"), PHASE_STATUSES, "phase status")
        strings!(phase.fetch("evidence"), "phase evidence")
        id
      end
      unique!(phase_ids, "phase ids")

      findings = array!(data.fetch("findings"), "findings")
      finding_ids = findings.map.with_index do |finding, index|
        object!(finding, "findings[#{index}]")
        exact_keys!(finding, CERTIFICATION_FINDING_KEYS, "findings[#{index}]")
        id = identifier!(finding.fetch("id"), "finding id")
        enum!(finding.fetch("severity"), SEVERITIES, "finding severity")
        enum!(finding.fetch("status"), FINDING_STATUSES, "finding status")
        id
      end
      unique!(finding_ids, "finding ids")

      if status == "passed"
        invalid!("passed certification requires every phase complete") unless phases.all? { |phase| phase.fetch("status") == "complete" }
        blockers = findings.select { |finding| %w[critical high].include?(finding.fetch("severity")) && finding.fetch("status") != "resolved" }
        invalid!("passed certification contains unresolved release blockers") if blockers.any?
      end
      freeze_contract(data)
    rescue KeyError => error
      invalid!("missing required key: #{error.key}")
    end

    private

    def validate_waiver!(waiver, status:, severity:)
      if status == "accepted"
        invalid!("critical and high findings cannot be accepted") if %w[critical high].include?(severity)
        object!(waiver, "waiver")
        exact_keys!(waiver, WAIVER_KEYS, "waiver")
        WAIVER_KEYS.first(3).each { |key| string!(waiver.fetch(key), "waiver #{key}") }
        approved_at = timestamp!(waiver.fetch("approved_at"), "waiver approved_at")
        expires_at = timestamp!(waiver.fetch("expires_at"), "waiver expires_at")
        invalid!("waiver must expire after approval") unless expires_at > approved_at
      else
        invalid!("waiver is only allowed for accepted findings") unless waiver.nil?
      end
    end

    def schema!(data)
      invalid!("schema_version must equal #{SCHEMA_VERSION}") unless data.fetch("schema_version") == SCHEMA_VERSION
    end

    def exact_keys!(object, expected, path)
      extra = object.keys - expected
      missing = expected - object.keys
      invalid!("#{path} has unsupported keys: #{extra.join(', ')}") if extra.any?
      invalid!("#{path} is missing keys: #{missing.join(', ')}") if missing.any?
    end

    def object!(value, path)
      invalid!("#{path} must be an object") unless value.is_a?(Hash)
      value
    end

    def array!(value, path)
      invalid!("#{path} must be an array") unless value.is_a?(Array)
      value
    end

    def nonempty_array!(value, path)
      array!(value, path)
      invalid!("#{path} must not be empty") if value.empty?
      value
    end

    def strings!(value, path)
      array!(value, path)
      value.each { |item| string!(item, path) }
      value
    end

    def string!(value, path)
      invalid!("#{path} must be a non-empty string") unless value.is_a?(String) && !value.strip.empty?
      value
    end

    def identifier!(value, path)
      string!(value, path)
      invalid!("#{path} must use lowercase kebab-case") unless /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/.match?(value)
      value
    end

    def enum!(value, allowed, path)
      invalid!("#{path} must be one of: #{allowed.join(', ')}") unless allowed.include?(value)
      value
    end

    def timestamp!(value, path)
      Time.iso8601(string!(value, path))
    rescue ArgumentError
      invalid!("#{path} must be an ISO 8601 timestamp")
    end

    def unique!(values, path)
      invalid!("#{path} must be unique") unless values.uniq.size == values.size
    end

    def freeze_contract(value)
      case value
      when Hash
        value.each { |key, nested| freeze_contract(key); freeze_contract(nested) }
      when Array
        value.each { |nested| freeze_contract(nested) }
      end
      value.freeze
    end

    def invalid!(message)
      raise InvalidContract, message
    end

    class InvalidContract < StandardError; end
  end
end

# frozen_string_literal: true

module OperationalReadiness
  class DiagnosticRedactor
    REDACTED = "[REDACTED]"
    PATTERNS = {
      authorization: /\bBearer\s+[A-Za-z0-9._~+\/=-]+/i,
      connection_url: %r{\b(?:postgres(?:ql)?|mysql2?|redis):\/\/[^\s"'<>]+}i,
      private_key: /-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----/m,
      jwt: /\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b/,
      access_token: /\b(?:gh[pousr]_[A-Za-z0-9_]{20,}|AKIA[A-Z0-9]{16})\b/,
      email: /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i
    }.freeze

    Result = Data.define(:value, :redactions)

    def redact(value)
      counts = Hash.new(0)
      redacted = redact_value(value, counts)
      Result.new(value: redacted, redactions: counts.sort.to_h)
    rescue StandardError
      raise RedactionFailed, "diagnostic redaction failed"
    end

    private

    def redact_value(value, counts)
      case value
      when Hash
        value.to_h do |key, item|
          if Security::SecretRegistry.redacted?(key) || sensitive_key?(key)
            counts["sensitive_key"] += 1
            [ key.to_s, REDACTED ]
          else
            [ key.to_s, redact_value(item, counts) ]
          end
        end
      when Array
        value.map { |item| redact_value(item, counts) }
      when String
        redact_text(value, counts)
      when Numeric, TrueClass, FalseClass, NilClass
        value
      else
        raise RedactionFailed, "unsupported diagnostic value"
      end
    end

    def redact_text(text, counts)
      PATTERNS.reduce(text.dup) do |value, (category, pattern)|
        value.gsub(pattern) do
          counts[category.to_s] += 1
          REDACTED
        end
      end
    end

    def sensitive_key?(key)
      key.to_s.downcase.match?(/api[_-]?key|private[_-]?key|database[_-]?url|credentials?/)
    end

    class RedactionFailed < StandardError; end
  end
end

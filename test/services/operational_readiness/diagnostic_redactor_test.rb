# frozen_string_literal: true

require "test_helper"

module OperationalReadiness
  class DiagnosticRedactorTest < ActiveSupport::TestCase
    test "redacts sensitive keys and secret patterns recursively" do
      value = {
        "password" => "do-not-keep",
        "nested" => [
          {
            "message" => "Authorization: Bearer abc.def-123",
            "database" => "postgresql://operator:password@database/app",
            "email" => "operator@example.com"
          }
        ]
      }

      result = DiagnosticRedactor.new.redact(value)
      serialized = JSON.generate(result.value)

      assert_equal DiagnosticRedactor::REDACTED, result.value.fetch("password")
      refute_includes serialized, "do-not-keep"
      refute_includes serialized, "abc.def-123"
      refute_includes serialized, "operator:password"
      refute_includes serialized, "operator@example.com"
      assert_operator result.redactions.values.sum, :>=, 4
    end

    test "fails closed for unsupported values" do
      assert_raises(DiagnosticRedactor::RedactionFailed) do
        DiagnosticRedactor.new.redact("callable" => -> { "not serializable" })
      end
    end
  end
end

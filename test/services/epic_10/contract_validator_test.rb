# frozen_string_literal: true

require "test_helper"

module Epic10
  class ContractValidatorTest < ActiveSupport::TestCase
    test "accepts strict versioned validation contracts" do
      plan = ContractValidator.validate_plan!(plan_data)
      finding = ContractValidator.validate_finding!(finding_data)
      certification = ContractValidator.validate_certification!(certification_data)

      assert_equal "epic-10-validation", plan.fetch("id")
      assert_equal "medium", finding.fetch("severity")
      assert_equal "passed", certification.fetch("status")
      assert_predicate plan, :frozen?
    end

    test "rejects unknown fields and duplicate phase identifiers" do
      assert_raises(ContractValidator::InvalidContract) do
        ContractValidator.validate_plan!(plan_data.merge("secret" => "not-allowed"))
      end

      duplicate = plan_data
      duplicate["phases"] << duplicate["phases"].first.dup
      error = assert_raises(ContractValidator::InvalidContract) do
        ContractValidator.validate_plan!(duplicate)
      end
      assert_includes error.message, "phase ids must be unique"
    end

    test "requires expiring human approval for accepted findings" do
      accepted = finding_data.merge(
        "status" => "accepted",
        "waiver" => {
          "owner" => "@maintainer",
          "rationale" => "Bounded residual risk",
          "approved_by" => "@release-owner",
          "approved_at" => "2026-08-01T00:00:00Z",
          "expires_at" => "2026-09-01T00:00:00Z"
        }
      )

      assert_equal "accepted", ContractValidator.validate_finding!(accepted).fetch("status")
      assert_raises(ContractValidator::InvalidContract) do
        ContractValidator.validate_finding!(accepted.merge("severity" => "high"))
      end
      assert_raises(ContractValidator::InvalidContract) do
        ContractValidator.validate_finding!(finding_data.merge("waiver" => accepted.fetch("waiver")))
      end
    end

    test "fails closed when a passed certification has incomplete phases or blockers" do
      incomplete = certification_data
      incomplete["phases"].first["status"] = "pending"
      assert_raises(ContractValidator::InvalidContract) do
        ContractValidator.validate_certification!(incomplete)
      end

      blocked = certification_data
      blocked["findings"] << { "id" => "security-1", "severity" => "high", "status" => "open" }
      assert_raises(ContractValidator::InvalidContract) do
        ContractValidator.validate_certification!(blocked)
      end
    end

    private

    def plan_data
      {
        "schema_version" => 1,
        "id" => "epic-10-validation",
        "owner" => "@csescobar",
        "phases" => [
          {
            "id" => "validation-architecture",
            "objective" => "Define validation evidence",
            "owner" => "@csescobar",
            "evidence_required" => [ "schema-validation" ]
          }
        ]
      }
    end

    def finding_data
      {
        "schema_version" => 1,
        "id" => "docs-1",
        "phase" => "validation-architecture",
        "severity" => "medium",
        "status" => "open",
        "summary" => "Example finding",
        "owner" => "@csescobar",
        "remediation" => "Update the documented contract",
        "evidence" => [],
        "waiver" => nil
      }
    end

    def certification_data
      {
        "schema_version" => 1,
        "id" => "epic-10-certification",
        "commit" => "a" * 40,
        "status" => "passed",
        "checked_at" => "2026-08-01T00:00:00Z",
        "phases" => [
          { "id" => "validation-architecture", "status" => "complete", "evidence" => [ "schema-validation" ] }
        ],
        "findings" => []
      }
    end
  end
end

# frozen_string_literal: true

module Upgrades
  class RecoveryAdvisor
    BACKUP_CODES = %w[
      backup_evidence_missing
      backup_evidence_stale
      backup_source_mismatch
    ].freeze
    COMPATIBILITY_CODES = %w[
      compatibility_failed
      contract_state_unavailable
      runtime_version_unavailable
      source_version_unavailable
    ].freeze

    def initialize(manifest:, execution_state: nil, findings: [])
      @manifest = manifest
      @execution_state = execution_state
      @findings = findings
    end

    def call
      return completed_execution_guidance if execution_state&.fetch("status", nil) == "completed" && findings.any?
      return blocker_guidance if findings.any?

      case execution_state&.fetch("status", nil)
      when "running"
        interrupted_guidance
      when "failed"
        failed_operation_guidance
      when "completed"
        raise NoRecoveryRequired, "completed upgrade has no recovery findings"
      else
        operator_guidance(
          "recovery_state_invalid",
          "The persisted upgrade state is missing or cannot be classified.",
          [
            "Keep maintenance mode active and preserve the execution state file.",
            "Inspect the execution and application logs using the same correlation window.",
            "Escalate to a platform operator before attempting another upgrade."
          ]
        )
      end
    end

    private

    attr_reader :manifest, :execution_state, :findings

    def blocker_guidance
      codes = findings.map { |finding| finding.fetch(:code, finding["code"]) }
      return backup_guidance if (codes & BACKUP_CODES).any?
      return compatibility_guidance if (codes & COMPATIBILITY_CODES).any?

      operator_guidance(
        "preflight_blocked",
        "Upgrade preflight reported blockers that require operator action.",
        [
          "Resolve every reported blocker without changing the target manifest.",
          "Run bin/upgrade preflight again and require a ready result.",
          "Do not start or resume execution while blockers remain."
        ]
      )
    end

    def backup_guidance
      operator_guidance(
        "backup_evidence_invalid",
        "Required backup evidence is missing, stale, or bound to a different source state.",
        [
          "Capture new database and persistent-file backups for the current installed state.",
          "Record fresh evidence with matching platform, schema, and installation contract values.",
          "Run preflight and backup-evidence verification again before execution."
        ]
      )
    end

    def compatibility_guidance
      operator_guidance(
        "compatibility_blocked",
        "The installed source state is not compatible with the target manifest.",
        [
          "Preserve the installed application and database state.",
          "Select an upgrade manifest whose source requirement and contracts match the installation.",
          "Run bin/upgrade preflight again; do not bypass compatibility checks."
        ]
      )
    end

    def completed_execution_guidance
      guidance(
        classification: "forward_recovery",
        failure_code: "post_upgrade_verification_failed",
        summary: "Execution completed, but post-upgrade verification did not certify the target state.",
        actions: [
          "Keep maintenance mode active and preserve execution, history, and backup evidence.",
          "Use the verification finding codes to repair the target state without replaying completed operations.",
          "Run post-upgrade verification again and release maintenance mode only after it succeeds."
        ]
      )
    end

    def interrupted_guidance
      guidance(
        classification: "retryable",
        failure_code: "execution_interrupted",
        summary: "Upgrade execution stopped before reaching a terminal state.",
        actions: [
          "Keep maintenance mode active and preserve the execution state file.",
          "Confirm the manifest and backup evidence still match the installed source state.",
          "Resume the same manifest; completed idempotent operations will be skipped."
        ]
      )
    end

    def failed_operation_guidance
      failed = Array(execution_state["operations"]).find { |operation| operation["status"] == "failed" }
      manifest_operation = manifest.operations.find { |operation| operation["id"] == failed&.fetch("id", nil) }
      return unknown_operation_guidance unless failed && manifest_operation

      if forward_recovery_required?(manifest_operation)
        guidance(
          classification: "forward_recovery",
          failure_code: "irreversible_operation_failed",
          summary: "An irreversible operation started or completed before the upgrade failed.",
          actions: [
            "Keep maintenance mode active and do not replay completed operations manually.",
            "Diagnose and repair the failed target operation using reviewed forward migrations.",
            "Resume the same manifest and run post-upgrade verification after execution completes."
          ],
          failed_operation_id: failed.fetch("id")
        )
      else
        guidance(
          classification: "retryable",
          failure_code: "retryable_operation_failed",
          summary: "The failed operation and all completed operations are declared reversible.",
          actions: [
            "Keep maintenance mode active and preserve the execution state file.",
            "Correct the external cause recorded in operational logs.",
            "Resume the same manifest; the executor will retry only the incomplete operation."
          ],
          failed_operation_id: failed.fetch("id")
        )
      end
    end

    def forward_recovery_required?(failed_operation)
      return true unless failed_operation.fetch("reversible")

      completed_ids = Array(execution_state["operations"]).filter_map do |operation|
        operation["id"] if operation["status"] == "completed"
      end
      manifest.operations.any? do |operation|
        completed_ids.include?(operation.fetch("id")) && !operation.fetch("reversible")
      end
    end

    def unknown_operation_guidance
      operator_guidance(
        "execution_state_unrecognized",
        "The failed operation cannot be matched to the target manifest.",
        [
          "Keep maintenance mode active and preserve all upgrade evidence.",
          "Confirm that the persisted state and target manifest belong to the same upgrade.",
          "Escalate to a platform operator; do not edit the state file or force a replay."
        ]
      )
    end

    def operator_guidance(failure_code, summary, actions)
      guidance(
        classification: "operator_intervention",
        failure_code: failure_code,
        summary: summary,
        actions: actions
      )
    end

    def guidance(classification:, failure_code:, summary:, actions:, failed_operation_id: nil)
      {
        "schema_version" => 1,
        "manifest_id" => manifest.id,
        "classification" => classification,
        "failure_code" => failure_code,
        "summary" => summary,
        "execution_status" => execution_state&.fetch("status", nil),
        "failed_operation_id" => failed_operation_id,
        "rollback" => {
          "automatic" => false,
          "reason" => "The baseline does not automate database or application rollback."
        },
        "actions" => actions.each_with_index.map do |instruction, index|
          { "order" => index + 1, "instruction" => instruction }
        end
      }
    end

    class NoRecoveryRequired < StandardError; end
  end
end

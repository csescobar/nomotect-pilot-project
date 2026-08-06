# frozen_string_literal: true

module OperationalReadiness
  class RestoreSafetyGate
    SUPPORTED_ENVIRONMENT = "production-like"

    def initialize(manifest:, plan:, maintenance:, confirmed_step_ids:, active_requests: 0, active_jobs: 0)
      @manifest = manifest
      @plan = plan
      @maintenance = maintenance
      @confirmed_step_ids = confirmed_step_ids
      @active_requests = active_requests
      @active_jobs = active_jobs
    end

    def findings
      results = []
      results << finding("backup_manifest_mismatch") unless plan.backup_manifest_id == manifest.id
      results << finding("production_like_target_required") unless plan.target.fetch("environment") == SUPPORTED_ENVIRONMENT
      results << finding("maintenance_mode_required") unless maintenance.active?
      results << finding("active_requests_present", count: active_requests) if active_requests.positive?
      results << finding("active_jobs_present", count: active_jobs) if active_jobs.positive?

      planned_components = plan.ordered_steps.pluck("component")
      unless planned_components.sort == BackupManifest::COMPONENT_KINDS.sort
        results << finding("restore_components_incomplete", components: planned_components)
      end

      unconfirmed = plan.ordered_steps.filter_map do |step|
        step.fetch("id") if step.fetch("operator_confirmation") && !confirmed_step_ids.include?(step.fetch("id"))
      end
      results << finding("operator_confirmation_required", step_ids: unconfirmed) if unconfirmed.any?
      results
    end

    def authorize!
      raise UnsafeRestore, findings unless findings.empty?

      true
    end

    private

    attr_reader :manifest, :plan, :maintenance, :confirmed_step_ids, :active_requests, :active_jobs

    def finding(code, details = {})
      { code:, details: }
    end

    class UnsafeRestore < StandardError
      attr_reader :findings

      def initialize(findings)
        @findings = findings
        super("restore safety requirements are not satisfied")
      end
    end
  end
end

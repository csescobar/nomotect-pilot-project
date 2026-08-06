# frozen_string_literal: true

module Upgrades
  class ExecutionSafetyGate
    def initialize(preflight_report:, evidence_findings:, maintenance:, active_requests: 0, active_jobs: 0)
      @preflight_report = preflight_report
      @evidence_findings = evidence_findings
      @maintenance = maintenance
      @active_requests = active_requests
      @active_jobs = active_jobs
    end

    def findings
      results = preflight_report.blockers + evidence_findings
      results << finding("maintenance_mode_required", "Maintenance mode must be active") unless maintenance.active?
      results << finding("active_requests_present", "Active application requests must drain", count: active_requests) if active_requests.positive?
      results << finding("active_jobs_present", "Active jobs must finish or be safely stopped", count: active_jobs) if active_jobs.positive?
      results
    end

    def ready? = findings.empty?

    def authorize!
      raise UnsafeExecution, findings unless ready?
      true
    end

    private

    attr_reader :preflight_report, :evidence_findings, :maintenance, :active_requests, :active_jobs

    def finding(code, message, details = {})
      { code:, message:, details: }
    end

    class UnsafeExecution < StandardError
      attr_reader :findings

      def initialize(findings)
        @findings = findings
        super("upgrade execution safety requirements are not satisfied")
      end
    end
  end
end

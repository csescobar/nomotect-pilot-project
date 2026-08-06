# frozen_string_literal: true

module Upgrades
  class Inspector
    def initialize(manifest:, detector: InstalledStateDetector.new)
      @manifest = manifest
      @detector = detector
    end

    def inspect
      state = detector.call
      InspectionReport.new(
        mode: :inspect,
        installed_state: state,
        manifest: manifest,
        blockers: observation_blockers(state),
        warnings: observation_warnings(state),
        operator_actions: manifest_operator_actions
      )
    end

    def preflight
      state = detector.call
      blockers = observation_blockers(state)
      warnings = observation_warnings(state)
      plan = compatible_plan(state, blockers)

      InspectionReport.new(
        mode: :preflight,
        installed_state: state,
        manifest: manifest,
        plan: plan,
        blockers: blockers,
        warnings: warnings,
        operator_actions: manifest_operator_actions
      )
    end

    private

    attr_reader :manifest, :detector

    def compatible_plan(state, blockers)
      return if blockers.any?

      Planner.new(
        manifest: manifest,
        current_version: state.dig("platform", "version"),
        runtime: state.fetch("runtime").merge("contracts" => state.fetch("contracts"))
      ).plan
    rescue Planner::IncompatibleUpgrade, ArgumentError => error
      blockers << finding("compatibility_failed", error.message)
      nil
    end

    def observation_blockers(state)
      findings = []
      if state.dig("platform", "version").nil?
        findings << finding("source_version_unavailable", "Installed platform version could not be detected")
      end
      unless state.dig("installation", "state") == "completed"
        findings << finding("installation_incomplete", "Installation state must be completed before upgrade")
      end
      findings << finding("database_unavailable", "Database state could not be inspected") unless state.dig("database", "available")

      pending = state.dig("database", "pending_migrations") || []
      if pending.any?
        findings << finding(
          "pending_source_migrations",
          "The installed source has pending database migrations",
          migrations: pending
        )
      end

      state.fetch("extensions", []).each do |extension|
        unless extension.fetch("status", "ready") == "ready"
          findings << finding(
            "extension_state_incompatible",
            "An enabled extension is missing, incompatible or unavailable",
            extension_id: extension.fetch("id"),
            status: extension.fetch("status"),
            finding_codes: extension.fetch("finding_codes", [])
          )
        end

        extension.fetch("pending_migrations", []).then do |extension_migrations|
          next if extension_migrations.empty?

          findings << finding(
            "pending_extension_migrations",
            "An enabled extension has pending database migrations",
            extension_id: extension.fetch("id"),
            migrations: extension_migrations
          )
        end
      end

      required_observations(state).each do |component|
        findings << finding("runtime_version_unavailable", "#{component} runtime version could not be detected", component: component)
      end

      required_contracts(state).each do |name|
        findings << finding("contract_state_unavailable", "Required installed contract could not be detected", contract: name)
      end
      findings
    end

    def observation_warnings(state)
      findings = []
      unless state.dig("generated_artifacts", "current")
        findings << finding(
          "generated_artifacts_stale",
          "Generated artifacts are stale or could not be verified",
          action: "Regenerate and verify artifacts before execution"
        )
      end
      manifest.deprecations.each do |deprecation|
        findings << finding(
          "contract_deprecated",
          "#{deprecation.fetch('contract')} is scheduled for removal in #{deprecation.fetch('remove_in')}",
          replacement: deprecation.fetch("replacement")
        )
      end
      findings
    end

    def required_observations(state)
      manifest.data.fetch("compatibility").slice("ruby", "rails", "postgresql").keys.select do |component|
        state.dig("runtime", component).nil?
      end
    end

    def required_contracts(state)
      manifest.data.dig("compatibility", "contracts").keys.reject { |name| state.fetch("contracts").key?(name) }
    end

    def manifest_operator_actions
      actions = manifest.operations.filter_map do |operation|
        next unless operation.fetch("type") == "operator_action"

        finding(
          "operator_action_required",
          operation.fetch("description"),
          operation_id: operation.fetch("id"),
          requires: operation.fetch("requires")
        )
      end
      if manifest.backup_required?
        actions.unshift(
          finding(
            "backup_evidence_required",
            "Provide the backup evidence declared by the target manifest",
            evidence: manifest.data.dig("backup", "evidence")
          )
        )
      end
      actions
    end

    def finding(code, message, details = {})
      {
        code: code,
        message: message,
        details: details
      }
    end
  end
end

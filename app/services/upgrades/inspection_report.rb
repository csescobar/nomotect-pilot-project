# frozen_string_literal: true

module Upgrades
  class InspectionReport
    attr_reader :mode, :installed_state, :manifest, :plan, :blockers, :warnings, :operator_actions

    def initialize(mode:, installed_state:, manifest:, plan: nil, blockers: [], warnings: [], operator_actions: [])
      @mode = mode.to_s
      @installed_state = installed_state
      @manifest = manifest
      @plan = plan
      @blockers = blockers.freeze
      @warnings = warnings.freeze
      @operator_actions = operator_actions.freeze
      freeze
    end

    def status
      return "blocked" if blockers.any?
      return "warnings" if warnings.any? || operator_actions.any?

      "ready"
    end

    def ready?
      blockers.empty?
    end

    def to_h
      {
        schema_version: 1,
        mode: mode,
        status: status,
        ready: ready?,
        installed_state: installed_state,
        target: {
          manifest_id: manifest.id,
          version: manifest.target_version.to_s
        },
        plan: plan&.to_h,
        blockers: blockers,
        warnings: warnings,
        operator_actions: operator_actions
      }
    end
  end
end

# frozen_string_literal: true

module Distributions
  class InspectionReport
    attr_reader :mode, :manifest, :repository, :source_commit, :channel_states,
      :blockers, :warnings, :operator_actions

    def initialize(
      mode:,
      manifest:,
      repository:,
      source_commit:,
      channel_states:,
      blockers: [],
      warnings: [],
      operator_actions: []
    )
      @mode = mode.to_s
      @manifest = manifest
      @repository = repository
      @source_commit = source_commit
      @channel_states = channel_states.freeze
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

    def ready? = blockers.empty?

    def to_h
      {
        schema_version: 1,
        mode: mode,
        status: status,
        ready: ready?,
        release: {
          version: manifest.version,
          tag: manifest.tag,
          source_commit: source_commit
        },
        repository: repository,
        channels: channel_states.map(&:data),
        blockers: blockers,
        warnings: warnings,
        operator_actions: operator_actions
      }
    end
  end
end

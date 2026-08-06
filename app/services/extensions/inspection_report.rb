# frozen_string_literal: true

module Extensions
  class InspectionReport
    attr_reader :mode, :configuration, :packages, :plan, :blockers, :warnings

    def initialize(mode:, configuration:, packages:, plan: nil, blockers: [], warnings: [])
      @mode = mode.to_s
      @configuration = configuration
      @packages = packages.freeze
      @plan = plan
      @blockers = blockers.freeze
      @warnings = warnings.freeze
      freeze
    end

    def status
      return "blocked" if blockers.any?
      return "warnings" if warnings.any?

      "ready"
    end

    def ready? = blockers.empty?

    def to_h
      {
        schema_version: 1,
        mode: mode,
        status: status,
        ready: ready?,
        configuration: {
          path: configuration.path&.to_s,
          enabled: configuration.enabled.size,
          required: configuration.required.size
        },
        extensions: packages.map(&:to_h),
        plan: plan&.to_h,
        blockers: blockers,
        warnings: warnings
      }
    end
  end
end

# frozen_string_literal: true

module Extensions
  class Inspector
    def initialize(
      configuration:,
      catalog: Catalog.new(configuration:),
      platform_version: Platform::Version.current,
      core_capabilities: {}
    )
      @configuration = configuration
      @catalog = catalog
      @platform_version = platform_version
      @core_capabilities = core_capabilities
    end

    def inspect
      discovery = catalog.discover
      InspectionReport.new(
        mode: :inspect,
        configuration: configuration,
        packages: discovery.packages,
        blockers: discovery.blockers
      )
    end

    def preflight
      discovery = catalog.discover
      return InspectionReport.new(
        mode: :preflight,
        configuration: configuration,
        packages: discovery.packages,
        blockers: discovery.blockers
      ) if discovery.blockers.any?

      result = CompatibilityPlanner.new(
        packages: discovery.packages,
        platform_version: platform_version,
        core_capabilities: core_capabilities
      ).call
      InspectionReport.new(
        mode: :preflight,
        configuration: configuration,
        packages: discovery.packages,
        plan: result.plan,
        blockers: result.blockers,
        warnings: result.warnings
      )
    end

    private

    attr_reader :configuration, :catalog, :platform_version, :core_capabilities
  end
end

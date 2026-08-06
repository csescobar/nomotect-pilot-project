# frozen_string_literal: true

module Extensions
  class CompatibilityPlanner
    Plan = Data.define(:platform_version, :load_order, :extensions) do
      def to_h
        {
          platform_version: platform_version,
          load_order: load_order,
          extensions: extensions
        }
      end
    end

    Result = Data.define(:plan, :blockers, :warnings) do
      def initialize(plan:, blockers:, warnings:)
        super(plan:, blockers: blockers.freeze, warnings: warnings.freeze)
      end
    end

    def initialize(packages:, platform_version:, core_capabilities: {})
      @packages = packages.sort_by(&:id)
      @platform_version = Gem::Version.new(platform_version.to_s)
      @core_capabilities = core_capabilities.transform_keys(&:to_s)
    end

    def call
      blockers = []
      validate_packages(blockers)
      validate_capabilities(blockers)
      load_order = dependency_order(blockers)
      plan = Plan.new(
        platform_version.to_s,
        blockers.empty? ? load_order.freeze : [].freeze,
        packages.map(&:to_h).freeze
      )

      Result.new(plan:, blockers:, warnings: [])
    end

    private

    attr_reader :packages, :platform_version, :core_capabilities

    def validate_packages(blockers)
      packages.each do |package|
        manifest = package.manifest
        unless requirement(manifest.platform_requirement).satisfied_by?(platform_version)
          blockers << finding(
            "platform_version_incompatible",
            "Extension does not support the installed platform version",
            extension_id: package.id,
            installed: platform_version.to_s,
            requirement: manifest.platform_requirement
          )
        end
        unless manifest.contract_version == Manifest::CONTRACT_VERSION
          blockers << finding(
            "extension_contract_incompatible",
            "Extension contract version is not supported",
            extension_id: package.id,
            installed: manifest.contract_version,
            supported: Manifest::CONTRACT_VERSION
          )
        end
      end
    end

    def validate_capabilities(blockers)
      providers = core_capabilities.to_h do |id, version|
        [ id, [ { provider: "platform", version: version } ] ]
      end
      packages.each do |package|
        package.manifest.provided_capabilities.each do |capability|
          providers[capability.fetch("id")] ||= []
          providers[capability.fetch("id")] << {
            provider: package.id,
            version: capability.fetch("version")
          }
        end
      end

      providers.each do |id, entries|
        next unless entries.many?

        blockers << finding(
          "capability_provider_conflict",
          "Capability has more than one provider",
          capability: id,
          providers: entries.pluck(:provider).sort
        )
      end

      packages.each do |package|
        package.manifest.required_capabilities.each do |required|
          validate_capability_requirement(package, required, providers, blockers)
        end
      end
    end

    def validate_capability_requirement(package, required, providers, blockers)
      entries = providers.fetch(required.fetch("id"), [])
      return if entries.many?

      if entries.empty?
        blockers << finding(
          "capability_missing",
          "Required capability has no provider",
          extension_id: package.id,
          capability: required.fetch("id")
        )
        return
      end

      provider = entries.first
      return if requirement(required.fetch("requirement")).satisfied_by?(
        Gem::Version.new(provider.fetch(:version).to_s)
      )

      blockers << finding(
        "capability_version_incompatible",
        "Required capability version is not satisfied",
        extension_id: package.id,
        capability: required.fetch("id"),
        installed: provider.fetch(:version),
        requirement: required.fetch("requirement")
      )
    end

    def dependency_order(blockers)
      packages_by_id = packages.index_by(&:id)
      dependencies = packages.to_h { |package| [ package.id, [] ] }

      packages.each do |package|
        package.manifest.dependencies.each do |dependency|
          target = packages_by_id[dependency.fetch("id")]
          unless target
            blockers << finding(
              "extension_dependency_missing",
              "Required extension dependency is not enabled",
              extension_id: package.id,
              dependency: dependency.fetch("id")
            )
            next
          end
          unless requirement(dependency.fetch("requirement")).satisfied_by?(Gem::Version.new(target.version))
            blockers << finding(
              "extension_dependency_incompatible",
              "Extension dependency version is not satisfied",
              extension_id: package.id,
              dependency: target.id,
              installed: target.version,
              requirement: dependency.fetch("requirement")
            )
          end
          dependencies.fetch(package.id) << target.id
        end
      end

      topological_order(dependencies, blockers)
    end

    def topological_order(dependencies, blockers)
      remaining = dependencies.transform_values { |items| items.uniq.sort }
      order = []

      until remaining.empty?
        ready = remaining.select { |_id, items| items.empty? }.keys.sort
        if ready.empty?
          blockers << finding(
            "extension_dependency_cycle",
            "Extension dependency graph contains a cycle",
            extensions: remaining.keys.sort
          )
          return []
        end

        order.concat(ready)
        ready.each { |id| remaining.delete(id) }
        remaining.each_value { |items| items.reject! { |id| ready.include?(id) } }
      end

      order
    end

    def requirement(value)
      Gem::Requirement.new(*value.to_s.split(",").map(&:strip))
    end

    def finding(code, message, details)
      {
        code: code,
        message: message,
        details: details
      }
    end
  end
end

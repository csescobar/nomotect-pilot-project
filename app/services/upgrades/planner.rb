# frozen_string_literal: true

module Upgrades
  class Planner
    Plan = Data.define(:manifest_id, :source_version, :target_version, :backup_required, :operations, :deprecations) do
      def to_h
        {
          manifest_id: manifest_id,
          source_version: source_version,
          target_version: target_version,
          backup_required: backup_required,
          operations: operations,
          deprecations: deprecations
        }
      end
    end

    def initialize(manifest:, current_version:, runtime: {})
      @manifest = manifest
      @current_version = Version.new(current_version)
      @runtime = runtime.transform_keys(&:to_s)
    end

    def plan
      validate_source!
      validate_target!
      validate_runtime!

      Plan.new(
        manifest.id,
        current_version.to_s,
        manifest.target_version.to_s,
        manifest.backup_required?,
        manifest.operations.map(&:dup).freeze,
        manifest.deprecations.map(&:dup).freeze
      )
    end

    private

    attr_reader :manifest, :current_version, :runtime

    def validate_source!
      return if current_version.satisfies?(manifest.source_requirement)

      raise IncompatibleUpgrade,
        "installed version #{current_version} does not satisfy #{manifest.source_requirement}"
    end

    def validate_target!
      return if manifest.target_version > current_version

      raise IncompatibleUpgrade,
        "target version #{manifest.target_version} must be newer than installed version #{current_version}"
    end

    def validate_runtime!
      compatibility = manifest.data.fetch("compatibility")
      %w[ruby rails postgresql].each do |component|
        installed = runtime[component]
        next if installed.nil? || Version.new(installed).satisfies?(compatibility.fetch(component))

        raise IncompatibleUpgrade,
          "#{component} version #{installed} does not satisfy #{compatibility.fetch(component)}"
      end

      installed_contracts = runtime.fetch("contracts", {}).transform_keys(&:to_s)
      compatibility.fetch("contracts").each do |name, required_version|
        installed_version = installed_contracts[name]
        next if installed_version.nil? || installed_version == required_version

        raise IncompatibleUpgrade,
          "contract #{name} version #{installed_version} does not match required version #{required_version}"
      end
    end

    class IncompatibleUpgrade < StandardError; end
  end
end

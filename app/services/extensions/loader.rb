# frozen_string_literal: true

require_relative "sdk"

module Extensions
  class Loader
    Result = Data.define(:loaded, :registry) do
      def to_h
        {
          status: "loaded",
          loaded: loaded,
          registry: registry.to_h
        }
      end
    end

    def initialize(report:, registry: Registry.new, requireer: nil)
      @report = report
      @registry = registry
      @requireer = requireer
    end

    def call
      @result ||= load_extensions
    end

    private

    attr_reader :report, :registry, :requireer

    def load_extensions
      packages = validated_packages
      loaded = []

      report.plan.load_order.each do |id|
        package = packages.fetch(id)
        load_package(package)
        loaded << id
      end

      registry.seal!
      Result.new(loaded.freeze, registry)
    end

    def validated_packages
      unless report.mode == "preflight" && report.ready? && report.plan
        raise IncompatiblePlan, "a ready preflight report is required before extension loading"
      end

      packages = report.packages.index_by(&:id)
      unless report.plan.load_order.uniq == report.plan.load_order &&
          report.plan.load_order.sort == packages.keys.sort
        raise IncompatiblePlan, "preflight load order must contain every discovered extension exactly once"
      end

      packages
    end

    def load_package(package)
      RegistrationContext.activate(registry:, package:) do
        if requireer
          requireer.call(package.manifest.entrypoint)
        else
          Kernel.require(package.entrypoint_path.to_s)
        end
      end
      return if registry.registered?(package.id)

      raise Registry::MissingRegistration, "extension entrypoint did not register its manifest id"
    rescue LoadError, StandardError => error
      raise LoadFailure.new(package.id, error.class.name), cause: nil
    end

    class IncompatiblePlan < StandardError; end

    class LoadFailure < StandardError
      attr_reader :extension_id, :cause_class

      def initialize(extension_id, cause_class)
        @extension_id = extension_id
        @cause_class = cause_class
        super("extension loading failed for #{extension_id}")
      end

      def to_h
        {
          code: "extension_load_failed",
          extension_id: extension_id,
          cause: cause_class
        }
      end
    end
  end
end

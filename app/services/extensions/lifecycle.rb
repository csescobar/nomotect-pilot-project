# frozen_string_literal: true

module Extensions
  class Lifecycle
    Result = Data.define(
      :status,
      :loaded,
      :skipped,
      :blockers,
      :warnings,
      :restart_required
    ) do
      def ready? = %w[ready degraded].include?(status)
      def traffic_allowed? = ready?

      def to_h
        {
          status: status,
          ready: ready?,
          traffic_allowed: traffic_allowed?,
          restart_required: restart_required,
          loaded: loaded,
          skipped: skipped,
          blocker_codes: blockers.pluck(:code).uniq.sort,
          warning_codes: warnings.pluck(:code).uniq.sort
        }
      end
    end

    def initialize(configuration:, inspector_factory: nil, loader_factory: nil)
      @configuration = configuration
      @inspector_factory = inspector_factory || ->(selected) { Inspector.new(configuration: selected) }
      @loader_factory = loader_factory || ->(report) { Loader.new(report:) }
    end

    def call
      report = inspector_factory.call(configuration).preflight
      skipped, warnings = optional_skips(report)
      report = inspector_factory.call(configuration_without(skipped)).preflight if skipped.any?
      return blocked_result(report.blockers, skipped, warnings) unless report.ready?

      loaded = loader_factory.call(report).call.loaded
      status = warnings.empty? ? "ready" : "degraded"
      result(status:, loaded:, skipped:, blockers: [], warnings:, restart_required: false)
    rescue Loader::LoadFailure => error
      result(
        status: "restart_required",
        loaded: [],
        skipped: skipped,
        blockers: [
          finding(
            "extension_load_failed",
            extension_id: error.extension_id,
            cause: error.cause_class
          )
        ],
        warnings: warnings,
        restart_required: true
      )
    rescue StandardError => error
      result(
        status: "restart_required",
        loaded: [],
        skipped: [],
        blockers: [ finding("extension_lifecycle_failed", cause: error.class.name) ],
        warnings: [],
        restart_required: true
      )
    end

    private

    attr_reader :configuration, :inspector_factory, :loader_factory

    def optional_skips(report)
      return [ [], [] ] if report.ready?

      optional_ids = configuration.enabled.reject { |item| item.fetch("required") }.pluck("id")
      scoped = report.blockers.map { |finding| [ finding, finding_extension_id(finding) ] }
      return [ [], [] ] if scoped.any? { |_finding, id| id.nil? || !optional_ids.include?(id) }

      skipped = scoped.pluck(1).uniq.sort
      warnings = skipped.map do |id|
        codes = scoped.filter_map { |finding, scoped_id| finding.fetch(:code) if scoped_id == id }
        finding("optional_extension_skipped", extension_id: id, finding_codes: codes.uniq.sort)
      end
      [ skipped, warnings ]
    end

    def finding_extension_id(finding)
      details = finding.fetch(:details)
      details[:extension_id] || details["id"]
    end

    def configuration_without(ids)
      Configuration.new(
        {
          "schema_version" => Configuration::SCHEMA_VERSION,
          "extensions" => configuration.extensions.reject { |item| ids.include?(item.fetch("id")) }.map(&:dup)
        },
        path: configuration.path
      )
    end

    def blocked_result(blockers, skipped, warnings)
      result(
        status: "blocked",
        loaded: [],
        skipped: skipped,
        blockers: blockers,
        warnings: warnings,
        restart_required: true
      )
    end

    def finding(code, **details)
      {
        code: code,
        message: code.tr("_", " "),
        details: details
      }
    end

    def result(status:, loaded:, skipped:, blockers:, warnings:, restart_required:)
      Result.new(
        status,
        loaded.freeze,
        skipped.freeze,
        blockers.freeze,
        warnings.freeze,
        restart_required
      ).freeze
    end
  end
end

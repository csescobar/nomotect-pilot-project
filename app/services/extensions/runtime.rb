# frozen_string_literal: true

module Extensions
  class Runtime
    class << self
      def boot!(configuration: nil, lifecycle_factory: nil)
        return result if @boot_attempted

        @boot_attempted = true
        configuration ||= Configuration.load_default
        lifecycle_factory ||= ->(selected) { Lifecycle.new(configuration: selected) }
        @result = lifecycle_factory.call(configuration).call
        log_result
        result
      rescue StandardError => error
        @result = Lifecycle::Result.new(
          "restart_required",
          [].freeze,
          [].freeze,
          [
            {
              code: "extension_runtime_failed",
              message: "extension runtime failed",
              details: { cause: error.class.name }
            }
          ].freeze,
          [].freeze,
          true
        ).freeze
        log_result
        result
      end

      def result
        @result ||= Lifecycle::Result.new(
          "not_started",
          [].freeze,
          [].freeze,
          [
            {
              code: "extension_runtime_not_started",
              message: "extension runtime not started",
              details: {}
            }
          ].freeze,
          [].freeze,
          true
        ).freeze
      end

      def ready? = result.ready?
      def traffic_allowed? = result.traffic_allowed?
      def readiness = result.to_h

      private

      def log_result
        Rails.logger.public_send(
          result.ready? ? :info : :error,
          event: "extensions.lifecycle",
          status: result.status,
          loaded: result.loaded,
          skipped: result.skipped,
          blocker_codes: result.blockers.pluck(:code).uniq.sort,
          restart_required: result.restart_required
        )
      end
    end
  end
end

module ServiceRequests
  class SlaTarget
    EXTENSION_ID = "nomotect.service-desk-sla"
    CAPABILITY_ID = "service-desk.sla-target"
    FALLBACK_TARGETS = {
      "low" => 96.hours,
      "medium" => 48.hours,
      "high" => 24.hours,
      "critical" => 4.hours
    }.freeze

    class << self
      def call(priority:)
        provider = capability_provider
        return fallback(priority) unless provider

        result = provider.call(priority: priority)
        return fallback(priority) unless result.is_a?(Hash)

        {
          priority: result[:priority] || priority,
          target_seconds: result[:target_seconds].to_i,
          deterministic: true
        }
      end

      def available?
        !capability_provider.nil?
      end

      private

      def capability_provider
        @capability_provider ||= resolve_provider
      end

      def resolve_provider
        registry = load_registry
        return unless registry

        entry = registry.fetch(EXTENSION_ID)
        entry.capabilities.fetch(CAPABILITY_ID).fetch(:provider)
      rescue KeyError, Extensions::Registry::MissingRegistration
        nil
      end

      def load_registry
        configuration = Extensions::Configuration.new({
          "schema_version" => 1,
          "extensions" => [ enabled_declaration ]
        })
        report = Extensions::Inspector.new(configuration: configuration).preflight
        return unless report.ready?

        Extensions::Loader.new(report: report).call.registry
      end

      def enabled_declaration
        default = Extensions::Configuration.load_default.extensions.find { |item| item.fetch("id") == EXTENSION_ID }
        (default || { "id" => EXTENSION_ID, "package" => "service-desk-sla" }).merge("enabled" => true)
      end

      def fallback(priority)
        target = FALLBACK_TARGETS.fetch(priority.to_s, 24.hours)
        { priority: priority, target_seconds: target.to_i, deterministic: true, source: "community" }
      end
    end
  end
end

# frozen_string_literal: true

module OperationalReadiness
  class DefaultDiagnosticCollectors
    CONFIGURATION_KEYS = %w[
      DATABASE_URL
      DEPLOYMENT_PROFILE
      INSTALLATION_ENABLED
      REDIS_URL
      SECRET_KEY_BASE
    ].freeze

    def initialize(installed_state: -> { Upgrades::InstalledStateDetector.new.call }, environment: ENV,
      operational_health: -> {
        OperationalHealthInspector.new(registry: DefaultHealthProviders.new.registry).call
      })
      @installed_state = installed_state
      @environment = environment
      @operational_health = operational_health
    end

    def registry
      DiagnosticCollectorRegistry.new
        .register("platform") { installed_state.call }
        .register("configuration") { configuration_presence }
        .register("operational_health") { operational_health.call }
    end

    private

    attr_reader :installed_state, :environment, :operational_health

    def configuration_presence
      {
        "keys" => CONFIGURATION_KEYS.to_h do |name|
          [ name, { "configured" => environment[name].present? } ]
        end
      }
    end
  end
end

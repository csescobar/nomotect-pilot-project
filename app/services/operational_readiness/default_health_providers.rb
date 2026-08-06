# frozen_string_literal: true

module OperationalReadiness
  class DefaultHealthProviders
    def initialize(installed_state: -> { Upgrades::InstalledStateDetector.new.call })
      @installed_state = installed_state
    end

    def registry
      HealthProviderRegistry.new
        .register("installation", category: "installation", required: true) { installation }
        .register("deployment", category: "deployment", required: true) { deployment }
        .register("jobs", category: "jobs", required: false) { jobs }
        .register("storage", category: "storage", required: true) { storage }
        .register("integrations", category: "integrations", required: false) { integrations }
    end

    private

    attr_reader :installed_state

    def state = @state ||= installed_state.call

    def installation
      ready = state.dig("installation", "state") == "completed"
      result(ready ? "healthy" : "unhealthy", ready ? "installation_ready" : "installation_incomplete",
        "contract_version" => state.dig("installation", "contract_version"))
    end

    def deployment
      profile = state.dig("deployment", "profile")
      result(profile.present? ? "healthy" : "degraded",
        profile.present? ? "deployment_ready" : "deployment_profile_unknown", "profile" => profile)
    end

    def jobs
      adapter = ActiveJob::Base.queue_adapter.class.name
      result(adapter.present? ? "healthy" : "unknown", adapter.present? ? "jobs_ready" : "job_adapter_unknown",
        "adapter" => adapter)
    end

    def storage
      service = ActiveStorage::Blob.service.class.name
      result(service.present? ? "healthy" : "unhealthy", service.present? ? "storage_ready" : "storage_service_unknown",
        "service" => service)
    end

    def integrations
      extensions = state.fetch("extensions", [])
      unhealthy = extensions.any? { |extension| extension.fetch("status", "ready") != "ready" }
      result(unhealthy ? "degraded" : "healthy", unhealthy ? "integration_unavailable" : "integrations_ready",
        "configured" => extensions.size)
    end

    def result(status, code, details)
      { "status" => status, "code" => code, "details" => details, "operator_actions" => [] }
    end
  end
end

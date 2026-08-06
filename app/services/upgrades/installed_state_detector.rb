# frozen_string_literal: true

module Upgrades
  class InstalledStateDetector
    SCHEMA_VERSION = 2
    CONTRACT_VERSIONS = {
      "installation-state" => Installation::StateStore::SCHEMA_VERSION,
      "installation-record" => 1,
      "upgrade-manifest" => Manifest::SCHEMA_VERSION,
      "upgrade-history" => 1
    }.freeze

    def initialize(
      version: nil,
      environment: Rails.env,
      installation_store: Installation::StateStore.new,
      connection: nil,
      migration_context: nil,
      generated_artifacts_current: nil,
      extension_state_provider: nil,
      clock: -> { Time.current.utc }
    )
      @version = version
      @environment = environment.to_s
      @installation_store = installation_store
      @connection = connection
      @migration_context = migration_context
      @generated_artifacts_current = generated_artifacts_current
      @extension_state_provider = extension_state_provider
      @clock = clock
    end

    def call
      contracts = CONTRACT_VERSIONS.dup
      deployment_contract = integer_environment("DEPLOYMENT_CONTRACT_VERSION")
      contracts["deployment-manifest"] = deployment_contract if deployment_contract

      {
        "schema_version" => SCHEMA_VERSION,
        "observed_at" => clock.call.iso8601,
        "environment" => environment,
        "platform" => { "version" => detected_version },
        "runtime" => {
          "ruby" => normalize_version(RUBY_VERSION),
          "rails" => normalize_version(Rails.gem_version.to_s),
          "postgresql" => database_version
        },
        "contracts" => contracts,
        "installation" => installation_state,
        "deployment" => {
          "contract_version" => deployment_contract,
          "profile" => ENV["DEPLOYMENT_PROFILE"].presence
        },
        "database" => database_state,
        "generated_artifacts" => {
          "current" => generated_artifacts_current?,
          "checks" => [ "design_tokens" ]
        },
        "extensions" => installed_extensions
      }
    end

    private

    attr_reader :version, :environment, :installation_store, :migration_context,
      :generated_artifacts_current, :extension_state_provider, :clock

    def detected_version
      candidate = version || ENV.values_at("PLATFORM_VERSION", "SOURCE_VERSION", "OCI_IMAGE_VERSION").find(&:present?)
      Version.new(candidate || Platform::Version.current.to_s).to_s
    rescue ArgumentError
      nil
    end

    def installation_state
      payload = installation_store.read
      {
        "contract_version" => payload.fetch("schema_version"),
        "state" => payload.fetch("state")
      }
    rescue StandardError => error
      {
        "contract_version" => nil,
        "state" => "unknown",
        "error" => error.class.name
      }
    end

    def database_state
      context = migration_context || default_migration_context
      statuses = context.migrations_status
      pending = statuses.filter_map do |status, migration_version, name|
        { "version" => migration_version.to_s, "name" => name } if status == "down"
      end
      {
        "available" => true,
        "schema_version" => context.current_version.to_s,
        "pending_migrations" => pending
      }
    rescue StandardError => error
      {
        "available" => false,
        "schema_version" => nil,
        "pending_migrations" => [],
        "error" => error.class.name
      }
    end

    def database_version
      normalize_version(connection.database_version.to_s)
    rescue StandardError
      nil
    end

    def default_migration_context
      ActiveRecord::MigrationContext.new(Rails.root.join("db/migrate"), connection.schema_migration)
    end

    def connection
      @connection ||= ActiveRecord::Base.connection
    end

    def generated_artifacts_current?
      return generated_artifacts_current.call if generated_artifacts_current.respond_to?(:call)
      return generated_artifacts_current unless generated_artifacts_current.nil?

      DesignTokens::Compiler.new.current?
    rescue StandardError
      false
    end

    def installed_extensions
      return extension_state_provider.call if extension_state_provider

      configuration = Extensions::Configuration.load_default
      report = Extensions::Inspector.new(
        configuration: configuration,
        platform_version: detected_version
      ).preflight
      Extensions::InstalledState.new(report:).call
    rescue StandardError
      [
        {
          "id" => "extension-state",
          "package" => "extension-state",
          "version" => nil,
          "required" => true,
          "contract_version" => nil,
          "status" => "unavailable",
          "finding_codes" => [ "extension_state_unavailable" ],
          "capabilities" => [],
          "components" => {
            "configuration" => false,
            "migrations" => { "namespace" => nil, "paths" => 0 },
            "routes" => { "namespace" => nil },
            "assets" => { "namespace" => nil },
            "documentation" => false
          },
          "pending_migrations" => []
        }
      ]
    end

    def integer_environment(name)
      value = ENV[name]
      Integer(value, 10) if value.present?
    rescue ArgumentError
      nil
    end

    def normalize_version(value)
      match = String(value).match(/\d+(?:\.\d+){0,2}/)
      raise ArgumentError, "version is unavailable" unless match

      segments = match[0].split(".")
      (segments + [ "0", "0" ]).first(3).join(".")
    end
  end
end

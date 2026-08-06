require "securerandom"

module Installation
  class DatabaseProvisioner
    def initialize(connector: DatabaseConnector.new, secret_store: SecretStore::EnvFile.new, progress: ProgressStore.new)
      @connector = connector
      @secret_store = secret_store
      @progress = progress
    end

    def provision!(configuration)
      configuration.validate!
      runtime_password = SecureRandom.base64(36)

      progress.publish(event: :connection, status: :started, message: "Connecting to PostgreSQL maintenance database")
      connector.with_connection(configuration) do |connection|
        progress.publish(event: :connection, status: :completed, message: "PostgreSQL connection established")
        ensure_role!(connection, configuration, runtime_password)
        ensure_database!(connection, configuration)
      end

      persist_runtime_credentials!(configuration, runtime_password)
      progress.publish(event: :provisioning, status: :completed, message: "Application database provisioning completed")
      Result.new(configuration.application_database, configuration.application_username)
    rescue StandardError => error
      progress.publish(event: :provisioning, status: :failed, message: safe_error_message(error))
      raise
    ensure
      configuration = nil
      runtime_password = nil
    end

    Result = Data.define(:database, :username)

    private

    attr_reader :connector, :secret_store, :progress

    def ensure_role!(connection, configuration, runtime_password)
      username = configuration.application_username
      exists = connection.exec_params("SELECT 1 FROM pg_roles WHERE rolname = $1", [ username ]).ntuples.positive?
      quoted_username = connection.quote_ident(username)
      quoted_password = connection.escape_literal(runtime_password)

      if exists
        connection.exec("ALTER ROLE #{quoted_username} WITH LOGIN PASSWORD #{quoted_password}")
        progress.publish(event: :role, status: :completed, message: "Application role updated")
      else
        connection.exec("CREATE ROLE #{quoted_username} WITH LOGIN PASSWORD #{quoted_password}")
        progress.publish(event: :role, status: :completed, message: "Application role created")
      end
    end

    def ensure_database!(connection, configuration)
      database = configuration.application_database
      username = configuration.application_username
      exists = connection.exec_params("SELECT 1 FROM pg_database WHERE datname = $1", [ database ]).ntuples.positive?
      quoted_database = connection.quote_ident(database)
      quoted_username = connection.quote_ident(username)

      if exists
        connection.exec("ALTER DATABASE #{quoted_database} OWNER TO #{quoted_username}")
        progress.publish(event: :database, status: :completed, message: "Application database ownership verified")
      else
        connection.exec("CREATE DATABASE #{quoted_database} OWNER #{quoted_username}")
        progress.publish(event: :database, status: :completed, message: "Application database created")
      end
    end

    def persist_runtime_credentials!(configuration, runtime_password)
      secret_store.write!(
        "DATABASE_HOST" => configuration.host,
        "DATABASE_PORT" => configuration.port,
        "DATABASE_NAME" => configuration.application_database,
        "DATABASE_USERNAME" => configuration.application_username,
        "DATABASE_PASSWORD" => runtime_password,
        "DATABASE_SSLMODE" => configuration.sslmode
      )
      progress.publish(event: :secrets, status: :completed, message: "Runtime database credentials persisted")
    end

    def safe_error_message(error)
      error.is_a?(DatabaseConnector::ConnectionError) ? error.message : "Database provisioning failed"
    end
  end
end

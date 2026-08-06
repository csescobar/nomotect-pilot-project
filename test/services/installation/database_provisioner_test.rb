require "test_helper"

class Installation::DatabaseProvisionerTest < ActiveSupport::TestCase
  test "creates missing role and database and persists only runtime credentials" do
    connection = FakeConnection.new(role_exists: false, database_exists: false)
    connector = FakeConnector.new(connection)
    secret_store = FakeSecretStore.new
    progress = FakeProgress.new

    result = Installation::DatabaseProvisioner.new(
      connector: connector,
      secret_store: secret_store,
      progress: progress
    ).provision!(configuration)

    assert_equal "app_database", result.database
    assert connection.sql.any? { |statement| statement.start_with?("CREATE ROLE") }
    assert connection.sql.any? { |statement| statement.start_with?("CREATE DATABASE") }
    assert_equal "app_runtime", secret_store.values.fetch("DATABASE_USERNAME")
    assert secret_store.values.fetch("DATABASE_PASSWORD").present?
    assert_not_includes secret_store.values.values, "temporary-secret"
    assert progress.events.any? { |event| event[:event] == :provisioning && event[:status] == :completed }
  end

  test "reconciles existing role and database" do
    connection = FakeConnection.new(role_exists: true, database_exists: true)

    Installation::DatabaseProvisioner.new(
      connector: FakeConnector.new(connection),
      secret_store: FakeSecretStore.new,
      progress: FakeProgress.new
    ).provision!(configuration)

    assert connection.sql.any? { |statement| statement.start_with?("ALTER ROLE") }
    assert connection.sql.any? { |statement| statement.start_with?("ALTER DATABASE") }
  end

  private

  def configuration
    Installation::DatabaseConfiguration.new(
      host: "localhost",
      port: 5432,
      maintenance_database: "postgres",
      admin_username: "postgres",
      admin_password: "temporary-secret",
      application_database: "app_database",
      application_username: "app_runtime",
      sslmode: "prefer"
    )
  end

  class FakeConnector
    def initialize(connection)
      @connection = connection
    end

    def with_connection(configuration)
      configuration.validate!
      yield @connection
    end
  end

  class FakeConnection
    Result = Data.define(:ntuples)

    attr_reader :sql

    def initialize(role_exists:, database_exists:)
      @role_exists = role_exists
      @database_exists = database_exists
      @sql = []
    end

    def exec_params(statement, parameters)
      @sql << statement
      exists = parameters.first == "app_runtime" ? @role_exists : @database_exists
      Result.new(exists ? 1 : 0)
    end

    def exec(statement)
      @sql << statement
    end

    def quote_ident(value)
      %Q("#{value}")
    end

    def escape_literal(value)
      %Q('#{value.gsub("'", "''")}')
    end
  end

  class FakeSecretStore
    attr_reader :values

    def write!(values)
      @values = values
    end
  end

  class FakeProgress
    attr_reader :events

    def initialize
      @events = []
    end

    def publish(event:, status:, message:)
      @events << { event: event, status: status, message: message }
    end
  end
end

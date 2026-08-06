require "test_helper"

class Installation::DatabaseConfigurationTest < ActiveSupport::TestCase
  test "accepts a valid PostgreSQL provisioning configuration" do
    configuration = Installation::DatabaseConfiguration.new(valid_attributes)

    assert_same configuration, configuration.validate!
    assert_equal 5432, configuration.port
    assert_equal "app_database", configuration.public_attributes.fetch("application_database")
    assert_not configuration.public_attributes.key?("admin_password")
  end

  test "rejects unsafe database identifiers" do
    configuration = Installation::DatabaseConfiguration.new(valid_attributes.merge(application_database: "app-database"))

    error = assert_raises(ArgumentError) { configuration.validate! }
    assert_match(/lowercase letters/, error.message)
  end

  test "rejects unsupported SSL modes" do
    configuration = Installation::DatabaseConfiguration.new(valid_attributes.merge(sslmode: "trust-me"))

    assert_raises(ArgumentError) { configuration.validate! }
  end

  private

  def valid_attributes
    {
      host: "localhost",
      port: 5432,
      maintenance_database: "postgres",
      admin_username: "postgres",
      admin_password: "temporary-secret",
      application_database: "app_database",
      application_username: "app_runtime",
      sslmode: "prefer"
    }
  end
end

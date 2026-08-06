require "test_helper"

class Installation::RuntimeDatabaseConfigurationTest < ActiveSupport::TestCase
  test "loads runtime database values without exposing the secret file" do
    path = Rails.root.join("tmp/runtime-database-#{Process.pid}.env")
    path.write(<<~ENV)
      DATABASE_HOST="db.internal"
      DATABASE_PORT="5432"
      DATABASE_NAME="platform"
      DATABASE_USERNAME="runtime"
      DATABASE_PASSWORD="secret-value"
      DATABASE_SSLMODE="require"
    ENV

    configuration = Installation::RuntimeDatabaseConfiguration.new(path: path).to_h

    assert_equal "platform", configuration.fetch(:database)
    assert_equal "runtime", configuration.fetch(:username)
    assert_equal "secret-value", configuration.fetch(:password)
  ensure
    FileUtils.rm_f(path)
  end

  test "rejects incomplete runtime configuration" do
    path = Rails.root.join("tmp/runtime-database-incomplete-#{Process.pid}.env")
    path.write("DATABASE_HOST=localhost\n")

    assert_raises(ArgumentError) do
      Installation::RuntimeDatabaseConfiguration.new(path: path).to_h
    end
  ensure
    FileUtils.rm_f(path)
  end
end

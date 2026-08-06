require "test_helper"
require "container_environment_validator"

class ContainerEnvironmentValidatorTest < ActiveSupport::TestCase
  test "accepts a valid production environment" do
    output = StringIO.new
    environment = {
      "DATABASE_URL" => "postgresql://runtime:secret@postgres:5432/platform",
      "SECRET_KEY_BASE" => "a" * 64
    }

    assert ContainerEnvironmentValidator.new(environment: environment, output: output).validate!
    assert_empty output.string
  end

  test "rejects missing required values without printing secrets" do
    output = StringIO.new
    environment = {
      "DATABASE_URL" => "postgresql://runtime:sensitive-password@postgres:5432/platform",
      "SECRET_KEY_BASE" => "short"
    }

    assert_not ContainerEnvironmentValidator.new(environment: environment, output: output).validate!
    assert_includes output.string, "SECRET_KEY_BASE must contain at least 64 characters"
    assert_not_includes output.string, "sensitive-password"
  end

  test "rejects unsupported database schemes" do
    output = StringIO.new
    environment = {
      "DATABASE_URL" => "mysql://runtime:secret@database/platform",
      "SECRET_KEY_BASE" => "a" * 64
    }

    assert_not ContainerEnvironmentValidator.new(environment: environment, output: output).validate!
    assert_includes output.string, "DATABASE_URL must use postgres or postgresql"
  end
end

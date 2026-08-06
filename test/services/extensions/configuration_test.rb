# frozen_string_literal: true

require "test_helper"

module Extensions
  class ConfigurationTest < ActiveSupport::TestCase
    test "accepts required and optional package declarations" do
      configuration = Configuration.new(configuration_data)

      assert_equal 2, configuration.enabled.size
      assert_equal [ "acme.audit-plus" ], configuration.required.pluck("id")
    end

    test "rejects duplicate extension identifiers" do
      data = configuration_data
      data["extensions"].last["id"] = data["extensions"].first["id"]

      error = assert_raises(Configuration::InvalidConfiguration) { Configuration.new(data) }
      assert_includes error.message, "ids must be unique"
    end

    test "requires operationally required packages to be enabled" do
      data = configuration_data
      data["extensions"].first["enabled"] = false

      error = assert_raises(Configuration::InvalidConfiguration) { Configuration.new(data) }
      assert_includes error.message, "required extensions must be enabled"
    end

    test "combines fixed configuration files and rejects duplicate declarations" do
      Dir.mktmpdir do |directory|
        root = Pathname(directory)
        platform = root.join("platform.yml")
        application = root.join("application.yml")
        platform.write(YAML.dump(configuration_data))
        application.write(YAML.dump({
          "schema_version" => 1,
          "extensions" => [ configuration_data.fetch("extensions").first ]
        }))

        error = assert_raises(Configuration::InvalidConfiguration) do
          Configuration.load_many([ platform, application ])
        end

        assert_includes error.message, "ids must be unique"
      end
    end

    private

    def configuration_data
      {
        "schema_version" => 1,
        "extensions" => [
          {
            "id" => "acme.audit-plus",
            "package" => "acme-audit-plus",
            "enabled" => true,
            "required" => true
          },
          {
            "id" => "acme.reporting",
            "package" => "acme-reporting",
            "enabled" => true,
            "required" => false
          }
        ]
      }
    end
  end
end

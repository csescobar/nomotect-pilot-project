# frozen_string_literal: true

require "test_helper"

module Extensions
  class CatalogTest < ActiveSupport::TestCase
    FakeSpecification = Data.define(:full_gem_path)

    test "discovers a manifest without loading its entrypoint" do
      Dir.mktmpdir do |directory|
        root = Pathname(directory)
        root.join("platform-extension.yml").write(YAML.dump(manifest_data))
        root.join("entrypoint.rb").write("raise 'entrypoint must not execute during discovery'\n")
        configuration = Configuration.new(configuration_data)
        catalog = Catalog.new(
          configuration:,
          resolver: ->(_package) { FakeSpecification.new(root.to_s) }
        )

        result = catalog.discover

        assert_empty result.blockers
        assert_equal [ "acme.audit-plus" ], result.packages.map(&:id)
      end
    end

    test "reports a missing configured package" do
      catalog = Catalog.new(
        configuration: Configuration.new(configuration_data),
        resolver: ->(_package) { nil }
      )

      result = catalog.discover

      assert_empty result.packages
      assert_equal [ "extension_package_missing" ], result.blockers.pluck(:code)
    end

    test "rejects a package whose manifest has another identity" do
      Dir.mktmpdir do |directory|
        root = Pathname(directory)
        data = manifest_data
        data["extension"]["id"] = "acme.other"
        root.join("platform-extension.yml").write(YAML.dump(data))
        catalog = Catalog.new(
          configuration: Configuration.new(configuration_data),
          resolver: ->(_package) { FakeSpecification.new(root.to_s) }
        )

        result = catalog.discover

        assert_equal [ "extension_identity_mismatch" ], result.blockers.pluck(:code)
      end
    end

    test "application resolver rejects a package symlink outside its fixed root" do
      Dir.mktmpdir do |directory|
        root = Pathname(directory)
        application_root = root.join("application/extensions")
        outside = root.join("outside")
        application_root.mkpath
        outside.mkpath
        application_root.join("escaped").make_symlink(outside)

        resolver = Catalog::SpecificationResolver.new(application_root:)

        assert_nil resolver.call("escaped")
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
          }
        ]
      }
    end

    def manifest_data
      {
        "schema_version" => 1,
        "extension" => {
          "id" => "acme.audit-plus",
          "version" => "1.2.0",
          "contract_version" => 1,
          "entrypoint" => "acme/audit_plus"
        },
        "platform" => { "requirement" => ">= 0.9.0, < 1.0.0" },
        "capabilities" => { "provides" => [], "requires" => [] },
        "dependencies" => [],
        "components" => {
          "configuration" => nil,
          "migrations" => { "namespace" => "acme.audit-plus", "paths" => [] },
          "routes" => { "namespace" => "acme.audit-plus" },
          "assets" => { "namespace" => "acme.audit-plus" },
          "documentation" => nil
        },
        "security" => { "trust" => "trusted_in_process" }
      }
    end
  end
end

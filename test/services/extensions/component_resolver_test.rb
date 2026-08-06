# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"
require_relative "../../support/extension_package_helper"

module Extensions
  class ComponentResolverTest < ActiveSupport::TestCase
    include ExtensionPackageHelper

    test "resolves every filesystem component inside the package root" do
      with_package_root do |root|
        package = package_at(root)
        components = ComponentResolver.new.resolve(package)

        assert_equal root.join("config/extension.schema.json").realpath, components.configuration
        assert_equal [ root.join("db/migrate").realpath ], components.migration_paths
        assert_equal "acme.audit", components.migration_namespace
        assert_equal "acme.audit", components.routes_namespace
        assert_equal "acme.audit", components.assets_namespace
        assert_equal root.join("docs/index.md").realpath, components.documentation
      end
    end

    test "rejects a component symlink that escapes the package root" do
      Dir.mktmpdir("external-extension-docs") do |external|
        File.write(File.join(external, "index.md"), "external")
        with_package_root do |root|
          FileUtils.rm_f(root.join("docs/index.md"))
          FileUtils.ln_s(File.join(external, "index.md"), root.join("docs/index.md"))

          error = assert_raises(ComponentResolver::InvalidComponent) do
            ComponentResolver.new.resolve(package_at(root))
          end

          assert_includes error.message, "inside the package root"
        end
      end
    end

    test "rejects missing declared component resources" do
      with_package_root do |root|
        FileUtils.rm_f(root.join("config/extension.schema.json"))

        assert_raises(ComponentResolver::InvalidComponent) do
          ComponentResolver.new.resolve(package_at(root))
        end
      end
    end

    private

    def with_package_root
      Dir.mktmpdir("extension-components") do |directory|
        root = Pathname(directory)
        FileUtils.mkdir_p(root.join("config"))
        FileUtils.mkdir_p(root.join("db/migrate"))
        FileUtils.mkdir_p(root.join("docs"))
        File.write(root.join("config/extension.schema.json"), "{}")
        File.write(root.join("docs/index.md"), "# Extension")
        yield root
      end
    end

    def package_at(root)
      package = extension_package(
        "acme.audit",
        configuration: "config/extension.schema.json",
        migration_paths: [ "db/migrate" ],
        documentation: "docs/index.md"
      )
      Package.new(declaration: package.declaration, root:, manifest: package.manifest)
    end
  end
end

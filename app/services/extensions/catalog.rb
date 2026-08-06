# frozen_string_literal: true

require "pathname"

module Extensions
  class Catalog
    MANIFEST_NAME = "platform-extension.yml"

    Result = Data.define(:packages, :blockers) do
      def initialize(packages:, blockers:)
        super(packages: packages.freeze, blockers: blockers.freeze)
      end
    end

    class SpecificationResolver
      Specification = Data.define(:full_gem_path)

      def initialize(application_root: Rails.root.join("application/extensions"))
        @application_root = Pathname(application_root)
      end

      def call(package_name)
        Gem.loaded_specs[package_name] || application_package(package_name)
      end

      private

      attr_reader :application_root

      def application_package(package_name)
        root = application_root.realpath
        package = root.join(package_name).realpath
        return unless package.to_s.start_with?("#{root}/")

        Specification.new(package.to_s)
      rescue Errno::ENOENT
        nil
      end
    end

    def initialize(configuration:, resolver: SpecificationResolver.new)
      @configuration = configuration
      @resolver = resolver
    end

    def discover
      packages = []
      blockers = []

      configuration.enabled.sort_by { |declaration| declaration.fetch("id") }.each do |declaration|
        discover_package(declaration, packages, blockers)
      end

      Result.new(packages:, blockers:)
    end

    private

    attr_reader :configuration, :resolver

    def discover_package(declaration, packages, blockers)
      specification = resolver.call(declaration.fetch("package"))
      unless specification
        blockers << finding(
          "extension_package_missing",
          "Configured extension package is not installed",
          declaration
        )
        return
      end

      root = Pathname(specification.full_gem_path).realpath
      manifest_path = bounded_manifest_path(root)
      manifest = Manifest.load(manifest_path)
      unless manifest.id == declaration.fetch("id")
        blockers << finding(
          "extension_identity_mismatch",
          "Configured extension id does not match the package manifest",
          declaration.merge("manifest_id" => manifest.id)
        )
        return
      end

      packages << Package.new(declaration:, root:, manifest:)
    rescue Errno::ENOENT, Manifest::InvalidManifest => error
      blockers << finding(
        "extension_manifest_invalid",
        "Configured extension manifest is missing or invalid",
        declaration.merge("error" => error.class.name)
      )
    end

    def bounded_manifest_path(root)
      path = root.join(MANIFEST_NAME).realpath
      return path if path.dirname == root

      raise Manifest::InvalidManifest, "extension manifest must remain inside the package root"
    end

    def finding(code, message, details)
      {
        code: code,
        message: message,
        details: details.slice("id", "package", "manifest_id", "error")
      }
    end
  end
end

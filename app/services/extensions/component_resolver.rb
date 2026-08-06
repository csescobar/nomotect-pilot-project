# frozen_string_literal: true

require "pathname"

module Extensions
  class ComponentResolver
    ComponentSet = Data.define(
      :extension_id,
      :configuration,
      :migration_namespace,
      :migration_paths,
      :routes_namespace,
      :assets_namespace,
      :documentation
    ) do
      def to_h
        {
          extension_id: extension_id,
          configuration: configuration&.to_s,
          migrations: {
            namespace: migration_namespace,
            paths: migration_paths.map(&:to_s)
          },
          routes: { namespace: routes_namespace },
          assets: { namespace: assets_namespace },
          documentation: documentation&.to_s
        }
      end
    end

    def resolve(package)
      components = package.manifest.components
      ComponentSet.new(
        package.id,
        optional_file(package, components.fetch("configuration"), "configuration"),
        components.dig("migrations", "namespace"),
        components.dig("migrations", "paths").map do |path|
          bounded_path(package, path, "migration", type: :directory)
        end.freeze,
        components.dig("routes", "namespace"),
        components.dig("assets", "namespace"),
        optional_file(package, components.fetch("documentation"), "documentation")
      ).freeze
    end

    private

    def optional_file(package, relative_path, component)
      return if relative_path.nil?

      bounded_path(package, relative_path, component, type: :file)
    end

    def bounded_path(package, relative_path, component, type:)
      root = package.root.realpath
      path = root.join(relative_path).realpath
      expected_type = type == :file ? path.file? : path.directory?
      unless inside?(path, root) && expected_type
        raise InvalidComponent, "#{component} component is not a valid #{type} inside the package root"
      end

      path.freeze
    rescue Errno::ENOENT, Errno::EACCES
      raise InvalidComponent, "#{component} component is unavailable inside the package root"
    end

    def inside?(path, root)
      path == root || path.to_s.start_with?("#{root}#{File::SEPARATOR}")
    end

    class InvalidComponent < StandardError; end
  end
end

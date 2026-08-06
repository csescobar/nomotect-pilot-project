# frozen_string_literal: true

require "pathname"

module Extensions
  class Package
    attr_reader :declaration, :root, :manifest

    def initialize(declaration:, root:, manifest:)
      @declaration = declaration.freeze
      @root = Pathname(root).freeze
      @manifest = manifest
      freeze
    end

    def id = manifest.id
    def package_name = declaration.fetch("package")
    def required? = declaration.fetch("required")
    def version = manifest.version

    def entrypoint_path
      lib_root = root.join("lib").realpath
      path = lib_root.join("#{manifest.entrypoint}.rb").realpath
      return path if path.to_s.start_with?("#{lib_root}/")

      raise InvalidEntrypoint, "extension entrypoint must remain inside the package lib directory"
    rescue Errno::ENOENT
      raise InvalidEntrypoint, "extension entrypoint is missing"
    end

    def to_h
      {
        id: id,
        package: package_name,
        version: version,
        required: required?,
        manifest_path: manifest.path&.to_s
      }
    end

    class InvalidEntrypoint < StandardError; end
  end
end

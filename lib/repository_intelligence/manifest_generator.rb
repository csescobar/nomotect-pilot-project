# frozen_string_literal: true

require "digest"
require "json"
require "pathname"

module RepositoryIntelligence
  class ManifestGenerator
    DEFAULT_ROOTS = %w[app config db docs lib test].freeze
    IGNORED_SEGMENTS = %w[.git log node_modules storage tmp vendor].freeze
    IGNORED_PREFIXES = %w[docs/ai/generated].freeze

    def initialize(repository_path:, repository_commit:, roots: DEFAULT_ROOTS)
      @repository_path = Pathname(repository_path).realpath
      @repository_commit = repository_commit
      @roots = roots
    end

    def generate
      files = discover_files.map do |path|
        relative = path.relative_path_from(repository_path).to_s
        {
          path: relative,
          kind: classify(relative),
          sha256: Digest::SHA256.file(path).hexdigest
        }
      end

      {
        schema_version: "1.0",
        repository_commit: repository_commit,
        generation_command: "ruby bin/repository-intelligence generate",
        files:
      }
    end

    def write(path)
      output = JSON.pretty_generate(generate) << "\n"
      Pathname(path).dirname.mkpath
      Pathname(path).write(output)
      output
    end

    private

    attr_reader :repository_path, :repository_commit, :roots

    def discover_files
      roots.flat_map do |root|
        base = repository_path.join(root)
        next [] unless base.directory?

        base.glob("**/*").select do |path|
          path.file? && safe_path?(path) && !ignored?(path)
        end
      end.sort_by { |path| path.relative_path_from(repository_path).to_s }
    end

    def safe_path?(path)
      path.realpath.to_s.start_with?("#{repository_path}/")
    rescue Errno::ENOENT
      false
    end

    def ignored?(path)
      relative = path.relative_path_from(repository_path).to_s
      IGNORED_PREFIXES.any? { |prefix| relative == prefix || relative.start_with?("#{prefix}/") } ||
        path.relative_path_from(repository_path).each_filename.any? { |segment| IGNORED_SEGMENTS.include?(segment) }
    end

    def classify(relative)
      case relative
      when %r{\Aapp/models/} then "model"
      when %r{\Aapp/controllers/} then "controller"
      when %r{\Aapp/jobs/} then "job"
      when %r{\Aapp/policies/} then "policy"
      when %r{\Aapp/components/} then "component"
      when %r{\Atest/} then "test"
      when %r{\Adocs/} then "documentation"
      when %r{\Adb/migrate/} then "migration"
      else "source"
      end
    end
  end
end

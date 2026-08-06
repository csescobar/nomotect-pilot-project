# frozen_string_literal: true

require "digest"
require "pathname"

module Distributions
  class GithubReleasePlan
    ARTIFACT_FILES = {
      "application_sbom" => "sbom.cdx.json",
      "application_starter_tar" => "nomotect-starter.tar.gz",
      "application_starter_zip" => "nomotect-starter.zip",
      "checksums" => "SHA256SUMS",
      "compatibility" => "compatibility.json",
      "container_sbom" => "container-sbom.cdx.json",
      "migration_notes" => "migration-notes.md",
      "packaging_manifest" => "packaging-manifest.json",
      "provenance" => "release-provenance.json",
      "release_notes" => "release-notes.md",
      "upgrade_notes" => "upgrade-notes.md"
    }.freeze

    attr_reader :manifest, :artifact_directory

    def initialize(manifest:, artifact_directory:)
      @manifest = manifest
      @artifact_directory = Pathname(artifact_directory).expand_path
      validate!
    end

    def tag = manifest.tag
    def target_commit = manifest.commit
    def prerelease? = Platform::Version.new(manifest.version).value.start_with?("0.")
    def notes_path = artifact_path("release_notes")

    def asset_paths
      manifest.artifacts.map { |id| artifact_path(id) }
    end

    def artifacts
      manifest.artifacts.map do |id|
        path = artifact_path(id)
        {
          id: id,
          name: path.basename.to_s,
          sha256: Digest::SHA256.file(path).hexdigest,
          size: path.size
        }
      end
    end

    def to_h
      {
        schema_version: 1,
        channel: "github_release",
        version: manifest.version,
        tag: tag,
        target_commit: target_commit,
        prerelease: prerelease?,
        notes: notes_path.to_s,
        assets: artifacts
      }
    end

    private

    def validate!
      raise InvalidBundle, "artifact directory is missing" unless artifact_directory.directory?
      raise InvalidBundle, "artifact directory cannot be a symbolic link" if artifact_directory.symlink?

      expected_ids = ARTIFACT_FILES.keys.sort
      raise InvalidBundle, "manifest artifact set is unsupported" unless manifest.artifacts.sort == expected_ids

      asset_paths.each { |path| validate_file!(path) }
      validate_checksums!
    end

    def validate_file!(path)
      raise InvalidBundle, "artifact is missing: #{path.basename}" unless path.file?
      raise InvalidBundle, "artifact cannot be a symbolic link: #{path.basename}" if path.symlink?
      raise InvalidBundle, "artifact escapes the bundle: #{path.basename}" unless
        path.realpath.to_s.start_with?("#{artifact_directory.realpath}/")
    end

    def validate_checksums!
      entries = checksum_entries
      expected = asset_paths.reject { |path| path.basename.to_s == "SHA256SUMS" }
      expected.each do |path|
        digest = Digest::SHA256.file(path).hexdigest
        raise InvalidBundle, "checksum is missing or invalid: #{path.basename}" unless
          entries[path.basename.to_s] == digest
      end
      extra = entries.keys - expected.map { |path| path.basename.to_s }
      raise InvalidBundle, "checksums contain unsupported artifacts: #{extra.join(', ')}" if extra.any?
    end

    def checksum_entries
      artifact_path("checksums").read.lines.to_h do |line|
        match = /\A([a-f0-9]{64})  ([A-Za-z0-9][A-Za-z0-9._-]*)\n?\z/.match(line)
        raise InvalidBundle, "SHA256SUMS has an invalid entry" unless match

        [ match[2], match[1] ]
      end
    end

    def artifact_path(id)
      filename = ARTIFACT_FILES.fetch(id) { raise InvalidBundle, "unsupported artifact id: #{id}" }
      artifact_directory.join(filename)
    end

    class InvalidBundle < StandardError; end
  end
end

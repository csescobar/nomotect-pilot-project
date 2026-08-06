# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "pathname"
require "tmpdir"
require_relative "../../../lib/application_starter"

module Distributions
  class BundleBuilder
    ARTIFACT_SOURCES = {
      "application_sbom" => [ :evidence, "sbom.cdx.json" ],
      "compatibility" => [ :release, "compatibility.json" ],
      "container_sbom" => [ :evidence, "container-sbom.cdx.json" ],
      "migration_notes" => [ :release, "migration-notes.md" ],
      "packaging_manifest" => [ :evidence, "packaging-manifest.json" ],
      "provenance" => [ :evidence, "release-provenance.json" ],
      "release_notes" => [ :release, "release-notes.md" ],
      "upgrade_notes" => [ :release, "upgrade-notes.md" ]
    }.freeze
    COMMIT = /\A[a-f0-9]{40}\z/

    attr_reader :release_directory, :evidence_directory, :output, :source_commit

    def initialize(release_directory:, evidence_directory:, output:, source_commit:)
      @release_directory = Pathname(release_directory).expand_path
      @evidence_directory = Pathname(evidence_directory).expand_path
      @output = Pathname(output).expand_path
      @source_commit = source_commit
    end

    def build!
      validate_inputs!
      metadata = load_json(release_path("release-metadata.json"))
      compatibility = load_json(release_path("compatibility.json"))
      evidence = load_evidence
      validate_consistency!(metadata, compatibility, evidence)
      manifest_data = distribution_manifest(metadata, compatibility)

      FileUtils.mkdir_p(output.dirname)
      staging = Pathname(Dir.mktmpdir("distribution-bundle-", output.dirname))
      begin
        artifacts = staging.join("artifacts")
        FileUtils.mkdir_p(artifacts)
        copy_artifacts!(artifacts)
        write_checksums!(artifacts)
        staging.join("release-metadata.json").write("#{JSON.pretty_generate(metadata)}\n")
        staging.join("distribution-manifest.json").write("#{JSON.pretty_generate(manifest_data)}\n")
        validate_output!(staging, manifest_data)
        File.rename(staging, output)
      ensure
        FileUtils.rm_rf(staging) if staging.exist?
      end

      {
        schema_version: 1,
        status: "ready",
        version: metadata.fetch("target_version"),
        source_commit: source_commit,
        manifest_digest: Digest::SHA256.hexdigest(
          Releases::CanonicalJson.generate(manifest_data)
        ),
        output: output.to_s
      }
    rescue JSON::ParserError,
      KeyError,
      ArgumentError,
      Manifest::InvalidManifest,
      GithubReleasePlan::InvalidBundle => error
      raise InvalidBundle, "distribution input is invalid: #{error.class.name}"
    end

    private

    def validate_inputs!
      raise InvalidBundle, "source commit has an invalid format" unless COMMIT.match?(source_commit)
      raise InvalidBundle, "release directory is missing" unless release_directory.directory?
      raise InvalidBundle, "release directory cannot be a symbolic link" if release_directory.symlink?
      raise InvalidBundle, "evidence directory is missing" unless evidence_directory.directory?
      raise InvalidBundle, "evidence directory cannot be a symbolic link" if evidence_directory.symlink?
      raise InvalidBundle, "distribution output already exists" if output.exist?
    end

    def load_evidence
      {
        application_sbom: load_json(evidence_path("sbom.cdx.json")),
        container_sbom: load_json(evidence_path("container-sbom.cdx.json")),
        packaging_manifest: load_json(evidence_path("packaging-manifest.json")),
        provenance: load_json(evidence_path("release-provenance.json"))
      }
    end

    def validate_consistency!(metadata, compatibility, evidence)
      version = metadata.fetch("target_version")
      report = Releases::ConsistencyValidator.new(
        version: version,
        tag: "v#{version}",
        release_metadata: metadata,
        release_notes: release_path("release-notes.md").read,
        compatibility: compatibility,
        application_sbom: evidence.fetch(:application_sbom),
        container_sbom: evidence.fetch(:container_sbom),
        packaging_manifest: evidence.fetch(:packaging_manifest),
        provenance: evidence.fetch(:provenance)
      ).call
      raise InvalidBundle, "release evidence is inconsistent" unless report.ready?

      commits = [
        evidence.dig(:packaging_manifest, "source", "commit"),
        evidence.dig(
          :provenance,
          "predicate",
          "buildDefinition",
          "externalParameters",
          "source_commit"
        ),
        sbom_commit(evidence.fetch(:application_sbom)),
        sbom_commit(evidence.fetch(:container_sbom))
      ]
      raise InvalidBundle, "release evidence belongs to another commit" unless
        commits.all? { |commit| commit == source_commit }
    end

    def distribution_manifest(metadata, compatibility)
      version = metadata.fetch("target_version")
      {
        schema_version: 1,
        release: {
          version: version,
          tag: "v#{version}",
          commit: source_commit,
          release_metadata_digest: digest(metadata),
          compatibility_digest: digest(compatibility)
        },
        repository: {
          identity: "repository_context",
          source_branch: "main"
        },
        channels: [
          {
            id: "github_release",
            enabled: true,
            prerelease: version.start_with?("0.")
          },
          {
            id: "ghcr",
            enabled: true,
            semantic_tags: %w[full minor],
            architectures: %w[linux/amd64 linux/arm64],
            rebuild: false,
            allow_latest: false
          }
        ],
        artifacts: Manifest::ARTIFACT_IDS.dup,
        policy: {
          approval_environment: "release",
          release_requires_approval: true,
          overwrite: false
        },
        recovery: {
          strategy: "resume_forward",
          partial_publication: "operator_review"
        }
      }
    end

    def copy_artifacts!(destination)
      copy_application_starter!(destination)
      ARTIFACT_SOURCES.each_value do |location, filename|
        source = location == :release ? release_path(filename) : evidence_path(filename)
        FileUtils.cp(source, destination.join(filename))
      end
    end

    def copy_application_starter!(destination)
      Dir.mktmpdir("nomotect-application-starter-") do |directory|
        result = ApplicationStarter::Builder.new(
          root: Rails.root,
          output: directory,
          version: JSON.parse(release_path("release-metadata.json").read).fetch("target_version"),
          source_commit: source_commit
        ).build!
        FileUtils.cp(result.fetch(:tar), destination.join("nomotect-starter.tar.gz"))
        FileUtils.cp(result.fetch(:zip), destination.join("nomotect-starter.zip"))
      end
    end

    def write_checksums!(directory)
      entries = directory.children.sort.map do |path|
        "#{Digest::SHA256.file(path).hexdigest}  #{path.basename}"
      end
      directory.join("SHA256SUMS").write("#{entries.join("\n")}\n")
    end

    def validate_output!(staging, manifest_data)
      manifest = Manifest.new(JSON.parse(JSON.generate(manifest_data)))
      GithubReleasePlan.new(
        manifest: manifest,
        artifact_directory: staging.join("artifacts")
      )
    end

    def release_path(filename) = bounded_file(release_directory, filename)
    def evidence_path(filename) = bounded_file(evidence_directory, filename)

    def bounded_file(root, filename)
      path = root.join(filename)
      raise InvalidBundle, "required distribution input is missing: #{filename}" unless path.file?
      raise InvalidBundle, "distribution input cannot be a symbolic link: #{filename}" if path.symlink?
      raise InvalidBundle, "distribution input escapes its directory: #{filename}" unless
        path.realpath.to_s.start_with?("#{root.realpath}/")

      path
    end

    def load_json(path) = JSON.parse(path.read)

    def sbom_commit(sbom)
      Array(sbom.dig("metadata", "properties")).find do |property|
        property.is_a?(Hash) && property["name"] == "source.commit"
      end&.fetch("value", nil)
    end

    def digest(value)
      Digest::SHA256.hexdigest(Releases::CanonicalJson.generate(value))
    end

    class InvalidBundle < StandardError; end
  end
end

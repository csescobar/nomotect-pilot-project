# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"

module Releases
  class Preparation
    RELEASE_PATTERN = /\A(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)\z/

    attr_reader :source_version, :target_version

    def initialize(target_version:, root: Rails.root)
      @root = Pathname(root)
      @source_version = Platform::Version.current(path: @root.join("VERSION"))
      @target_version = Platform::Version.new(target_version)
      @catalog = ChangeCatalog.new(path: @root.join("changes"))
      @fragments = @catalog.fragments
      @generator = NotesGenerator.new(
        fragments: @fragments,
        released_fragments: @catalog.released_fragments,
        current_version: @source_version.to_s,
        root: @root
      )
    end

    def validate
      findings = []
      findings << "target version must be a stable semantic version" unless RELEASE_PATTERN.match?(target_version.to_s)
      findings << "target version must be newer than #{source_version}" unless target_version > source_version
      findings << "at least one change fragment is required" if fragments.empty?
      unless satisfies_release_impact?
        findings << "target version does not satisfy #{generator.release_impact} release impact"
      end
      archive = root.join("changes/archive", target_version.to_s)
      findings << "release archive already exists for #{target_version}" if archive.exist?
      findings
    end

    def plan
      ensure_valid!
      {
        schema_version: 1,
        source_version: source_version.to_s,
        target_version: target_version.to_s,
        release_impact: generator.release_impact,
        fragment_ids: fragments.map(&:id).sort,
        paths: planned_paths
      }
    end

    def apply!
      ensure_valid!
      release_documents = generator.release_documents(target_version.to_s)
      compatibility = release_compatibility
      metadata = release_metadata(compatibility)
      archive_fragments!
      root.join("VERSION").write("#{target_version}\n")
      write_versioned_documents(release_documents, metadata, compatibility)
      NotesGenerator.new(root:, current_version: target_version.to_s).write!
      plan_after_apply(metadata)
    end

    private

    attr_reader :root, :catalog, :fragments, :generator

    def ensure_valid!
      findings = validate
      raise InvalidPreparation, findings.join("; ") if findings.any?
    end

    def satisfies_release_impact?
      source = source_version.value.split(".").first(3).map(&:to_i)
      target = target_version.value.split(".").first(3).map(&:to_i)
      case generator.release_impact
      when "none", "patch" then target_version > source_version
      when "minor" then target[0] > source[0] || target[0] == source[0] && target[1] > source[1]
      when "major" then target[0] > source[0]
      end
    end

    def planned_paths
      fragment_paths = fragments.map do |fragment|
        "changes/archive/#{target_version}/#{Pathname(fragment.path).basename}"
      end
      [
        "VERSION",
        "CHANGELOG.md",
        "docs/releases/generated/unreleased.md",
        "docs/releases/generated/migration-notes.md",
        "docs/releases/generated/upgrade-notes.md",
        "docs/releases/#{target_version}/release-notes.md",
        "docs/releases/#{target_version}/migration-notes.md",
        "docs/releases/#{target_version}/upgrade-notes.md",
        "docs/releases/#{target_version}/compatibility.json",
        "docs/releases/#{target_version}/release-metadata.json",
        *fragment_paths
      ].sort
    end

    def release_metadata(compatibility)
      payload = {
        schema_version: 1,
        source_version: source_version.to_s,
        target_version: target_version.to_s,
        release_impact: generator.release_impact,
        fragment_ids: fragments.map(&:id).sort,
        compatibility_digest: Digest::SHA256.hexdigest(CanonicalJson.generate(compatibility))
      }
      normalized_fragments = fragments.sort_by(&:id).map(&:data)
      payload[:fragment_digest] = Digest::SHA256.hexdigest(CanonicalJson.generate(normalized_fragments))
      payload
    end

    def release_compatibility
      {
        schema_version: 1,
        source_version: source_version.to_s,
        platform_version: target_version.to_s,
        contracts: {
          change_fragment: ChangeFragment::SCHEMA_VERSION,
          installed_platform_state: Upgrades::InstalledStateDetector::SCHEMA_VERSION,
          release_metadata: 1,
          upgrade_manifest: Upgrades::Manifest::SCHEMA_VERSION
        }
      }
    end

    def archive_fragments!
      destination = root.join("changes/archive", target_version.to_s)
      destination.mkpath
      fragments.each do |fragment|
        FileUtils.mv(fragment.path, destination.join(Pathname(fragment.path).basename))
      end
    end

    def write_versioned_documents(documents, metadata, compatibility)
      directory = root.join("docs/releases", target_version.to_s)
      directory.mkpath
      documents.each { |name, content| directory.join(name).write(content) }
      directory.join("compatibility.json").write("#{JSON.pretty_generate(compatibility)}\n")
      directory.join("release-metadata.json").write("#{JSON.pretty_generate(metadata)}\n")
    end

    def plan_after_apply(metadata)
      metadata.merge(paths: planned_paths)
    end

    class InvalidPreparation < StandardError; end
  end
end

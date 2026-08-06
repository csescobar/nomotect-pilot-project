# frozen_string_literal: true

require "yaml"

module Epic10
  class RcUpgradeFixture
    class InvalidFixture < StandardError; end

    REQUIRED_STATE = %w[database_revision configuration_revision generated_artifacts_revision extension_api].freeze
    REQUIRED_EVIDENCE = %w[deterministic credential_free source_commit_required].freeze

    def initialize(root: Rails.root.join("test/support/epic_10/upgrades"))
      @root = Pathname(root)
    end

    def call
      source = load_state("representative-app-rc.1.yml")
      target = load_state("representative-app-rc.2.yml")
      manifest_data = load_yaml("rc.1-to-rc.2.yml")
      manifest = Upgrades::Manifest.new(manifest_data)

      validate_transition!(source, target, manifest)

      {
        "schema_version" => 1,
        "status" => "passed",
        "application_id" => source.fetch("application_id"),
        "source_candidate" => source.fetch("candidate"),
        "target_candidate" => target.fetch("candidate"),
        "manifest_id" => manifest.id,
        "backup_required" => manifest.backup_required?,
        "operation_ids" => manifest.operations.pluck("id"),
        "credential_free" => true
      }
    rescue KeyError, Psych::Exception, Errno::ENOENT, Upgrades::Manifest::InvalidManifest => error
      raise InvalidFixture, error.message
    end

    private

    attr_reader :root

    def load_state(name)
      state = load_yaml(name)
      raise InvalidFixture, "#{name} schema_version must be 1" unless state["schema_version"] == 1
      raise InvalidFixture, "#{name} has incomplete state" unless REQUIRED_STATE.all? { |key| state.fetch("state", {}).key?(key) }
      raise InvalidFixture, "#{name} evidence must fail closed" unless REQUIRED_EVIDENCE.all? { |key| state.fetch("evidence", {})[key] == true }

      state
    end

    def load_yaml(name)
      YAML.safe_load_file(root.join(name), aliases: false)
    end

    def validate_transition!(source, target, manifest)
      source_version = Upgrades::Version.new(source["candidate"])
      target_version = Upgrades::Version.new(target["candidate"])

      raise InvalidFixture, "application identifiers differ" unless source["application_id"] == target["application_id"]
      raise InvalidFixture, "manifest source does not match fixture" unless source_version.satisfies?(manifest.source_requirement)
      raise InvalidFixture, "manifest target does not match fixture" unless manifest.target_version.to_s == target_version.to_s
      raise InvalidFixture, "pre-upgrade backup evidence is required" unless manifest.backup_required?
      raise InvalidFixture, "candidate state must advance" unless target_version > source_version
    end
  end
end

# frozen_string_literal: true

require "yaml"

module Epic10
  class ProductionDeploymentCertification
    class InvalidCertification < StandardError; end

    def initialize(source_commit:, path: Rails.root.join("config/epic_10/production-deployment.yml"))
      @source_commit = String(source_commit)
      @path = Pathname(path)
    end

    def call
      validate_source_commit!
      data = YAML.safe_load_file(path, aliases: false)
      checks = Array(data.fetch("required_checks"))
      observations = data.fetch("observations")
      raise InvalidCertification, "deployment checks are missing" if checks.empty?
      raise InvalidCertification, "deployment observation is incomplete" unless checks.all? { |check| observations[check] == "passed" }
      evidence = data.fetch("evidence")
      raise InvalidCertification, "deployment evidence must fail closed" unless %w[deterministic credential_free source_commit_required].all? { |key| evidence[key] == true }
      raise InvalidCertification, "production data is forbidden" unless evidence["production_data"] == false
      raise InvalidCertification, "deployment certification cannot publish" unless data.dig("publication", "allowed") == false

      {
        "schema_version" => 1,
        "phase" => 5,
        "status" => "passed",
        "source_commit" => source_commit,
        "profile" => data.fetch("profile"),
        "checks" => checks.map { |id| { "id" => id, "status" => observations.fetch(id) } },
        "credential_free" => true,
        "publication" => { "allowed" => false }
      }
    rescue KeyError, Psych::Exception, Errno::ENOENT => error
      raise InvalidCertification, error.message
    end

    private

    attr_reader :source_commit, :path

    def validate_source_commit!
      raise InvalidCertification, "source commit must be a full lowercase SHA" unless /\A[0-9a-f]{40}\z/.match?(source_commit)
    end
  end
end

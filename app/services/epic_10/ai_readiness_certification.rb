# frozen_string_literal: true

require "yaml"

module Epic10
  class AiReadinessCertification
    class InvalidCertification < StandardError; end

    REQUIRED_VALIDATION = %w[focused_tests contract_certification release_contract draft_review_required].freeze
    REQUIRED_EVIDENCE = %w[deterministic credential_free production_data_free].freeze

    def initialize(source_commit:, path: Rails.root.join("config/epic_10/ai-readiness.yml"))
      @source_commit = String(source_commit)
      @path = Pathname(path)
    end

    def call
      raise InvalidCertification, "source commit must be a full lowercase SHA" unless /\A[0-9a-f]{40}\z/.match?(source_commit)

      data = YAML.safe_load_file(path, aliases: false)
      journey = data.fetch("journey")
      raise InvalidCertification, "journey must represent an unfamiliar contributor" unless journey.fetch("contributor_profile") == "unfamiliar"

      guidance = Array(journey.fetch("guidance"))
      steps = Array(journey.fetch("steps"))
      raise InvalidCertification, "repository-native guidance is required" if guidance.empty?
      raise InvalidCertification, "contributor journey is incomplete" if steps.empty?
      raise InvalidCertification, "undocumented contributor context is forbidden" unless steps.all? { |step| step["documented_context"] == true && guidance.include?(step["evidence"]) }

      boundary = data.fetch("change_boundary")
      paths = Array(boundary.fetch("allowed_paths"))
      raise InvalidCertification, "change boundary is invalid" if paths.empty? || paths.any? { |item| item.start_with?("/") || item.split("/").include?("..") }
      raise InvalidCertification, "public contracts are required" if Array(boundary.fetch("public_contracts")).empty?
      raise InvalidCertification, "protected internals may not be modified" unless boundary.fetch("protected_internals_modified") == false

      validation = data.fetch("validation")
      raise InvalidCertification, "required validation is incomplete" unless REQUIRED_VALIDATION.all? { |key| validation[key] == true }

      evidence = data.fetch("evidence")
      raise InvalidCertification, "undocumented context threshold breached" unless evidence.fetch("undocumented_context_steps") == 0
      raise InvalidCertification, "bounded change was not completed" unless evidence.fetch("bounded_change_completion") == true
      raise InvalidCertification, "evidence safeguards are incomplete" unless REQUIRED_EVIDENCE.all? { |key| evidence[key] == true }
      raise InvalidCertification, "certification cannot publish" unless data.dig("publication", "allowed") == false

      {
        "schema_version" => 1,
        "phase" => 6,
        "status" => "passed",
        "source_commit" => source_commit,
        "journey" => journey,
        "change_boundary" => boundary,
        "validation" => validation,
        "evidence" => evidence,
        "findings" => data.fetch("findings"),
        "publication" => { "allowed" => false }
      }
    rescue KeyError, Psych::Exception, Errno::ENOENT => error
      raise InvalidCertification, error.message
    end

    private

    attr_reader :source_commit, :path
  end
end

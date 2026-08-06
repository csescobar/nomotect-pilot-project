# frozen_string_literal: true

require "yaml"

module Epic10
  class AccessibilityCertification
    class InvalidCertification < StandardError; end

    REQUIRED_CHECKS = %w[semantic_structure keyboard_operation focus_management accessible_names status_announcements contrast_light contrast_dark browser_journeys].freeze

    def initialize(source_commit:, path: Rails.root.join("config/epic_10/accessibility.yml"))
      @source_commit = String(source_commit)
      @path = Pathname(path)
    end

    def call
      raise InvalidCertification, "source commit must be a full lowercase SHA" unless /\A[0-9a-f]{40}\z/.match?(source_commit)
      data = YAML.safe_load_file(path, aliases: false)
      checks = data.fetch("automated_checks")
      raise InvalidCertification, "accessibility checks are incomplete" unless REQUIRED_CHECKS.all? { |id| checks[id] == "passed" }
      thresholds = data.fetch("thresholds")
      raise InvalidCertification, "accessibility threshold breached" unless thresholds["critical_violations"] == 0 && thresholds["keyboard_blockers"] == 0
      raise InvalidCertification, "Light and Dark are required" unless data.fetch("supported_themes") == %w[light dark]
      raise InvalidCertification, "English and Brazilian Portuguese are required" unless data.fetch("supported_locales") == [ "en", "pt-BR" ]
      manual = data.dig("manual_reviews", "screen_reader")
      raise InvalidCertification, "screen-reader review must remain human-required" unless manual == { "required" => true, "approved" => false, "authority" => "human" }
      raise InvalidCertification, "accessibility certification cannot publish" unless data.dig("publication", "allowed") == false

      {
        "schema_version" => 1, "phase" => 6, "status" => "automated_pass",
        "source_commit" => source_commit,
        "checks" => REQUIRED_CHECKS.map { |id| { "id" => id, "status" => checks.fetch(id) } },
        "thresholds" => thresholds,
        "manual_screen_reader_review" => manual,
        "stable_release_ready" => false,
        "publication" => { "allowed" => false }
      }
    rescue KeyError, Psych::Exception, Errno::ENOENT => error
      raise InvalidCertification, error.message
    end

    private

    attr_reader :source_commit, :path
  end
end

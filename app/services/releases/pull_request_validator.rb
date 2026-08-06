# frozen_string_literal: true

module Releases
  class PullRequestValidator
    EXEMPT_PATTERNS = [
      %r{\Adocs/},
      %r{\Atest/},
      %r{\Achanges/},
      %r{\A(?:README|AGENTS|CONTRIBUTING|SECURITY|LICENSE)(?:\.md)?\z}
    ].freeze
    CONTRACT_PATTERNS = [
      %r{\Adocs/contracts/},
      %r{\Aconfig/ai/contracts/},
      %r{\Aconfig/ai/schemas/}
    ].freeze

    def initialize(changed_paths:, pull_request_number: nil)
      @changed_paths = changed_paths.map(&:to_s).uniq.sort
      @pull_request_number = pull_request_number&.to_s
    end

    def call
      findings = []
      fragments = changed_fragment_paths.filter_map do |path|
        ChangeFragment.load(path)
      rescue ChangeFragment::InvalidFragment => error
        findings << finding("change_fragment_invalid", error.message, path: path)
        nil
      end

      if release_relevant_paths.any? && fragments.empty? && !release_preparation?
        findings << finding(
          "change_fragment_missing",
          "Release-relevant pull requests must add or update a change fragment",
          paths: release_relevant_paths
        )
      end
      validate_identifiers(fragments, findings)
      validate_migrations(fragments, findings)
      validate_contract_changes(fragments, findings)

      Report.new(findings)
    end

    private

    attr_reader :changed_paths, :pull_request_number

    def changed_fragment_paths
      changed_paths.grep(%r{\Achanges/[^/]+\.yml\z}).select { |path| File.file?(path) }
    end

    def release_relevant_paths
      changed_paths.reject { |path| EXEMPT_PATTERNS.any? { |pattern| pattern.match?(path) } }
    end

    def validate_identifiers(fragments, findings)
      return if release_preparation?
      return if fragments.empty? && release_relevant_paths.empty?
      return if pull_request_number.blank?
      return if fragments.any? { |fragment| fragment.id.start_with?("#{pull_request_number}-") }

      findings << finding(
        "change_fragment_pr_mismatch",
        "A change fragment id must begin with the pull request number",
        pull_request_number: pull_request_number
      )
    end

    def validate_migrations(fragments, findings)
      return unless changed_paths.any? { |path| path.start_with?("db/migrate/") }
      return if fragments.any? { |fragment| fragment.data.dig("migration", "required") }

      findings << finding(
        "migration_impact_missing",
        "Database migration changes must declare required migration notes"
      )
    end

    def validate_contract_changes(fragments, findings)
      return unless changed_paths.any? { |path| CONTRACT_PATTERNS.any? { |pattern| pattern.match?(path) } }
      return if fragments.any? { |fragment| fragment.contracts.any? && fragment.release_impact != "none" }

      findings << finding(
        "contract_impact_missing",
        "Contract changes must name affected contracts and declare release impact"
      )
    end

    def release_preparation?
      allowed = [
        %r{\AVERSION\z},
        %r{\ACHANGELOG\.md\z},
        %r{\Achanges/},
        %r{\Adocs/releases/}
      ]
      changed_paths.include?("VERSION") &&
        changed_paths.any? { |path| %r{\Achanges/archive/[^/]+/[^/]+\.yml\z}.match?(path) } &&
        changed_paths.any? { |path| %r{\Adocs/releases/[^/]+/release-metadata\.json\z}.match?(path) } &&
        changed_paths.all? { |path| allowed.any? { |pattern| pattern.match?(path) } }
    end

    def finding(code, message, details = {})
      { code: code, message: message, details: details }
    end

    class Report
      attr_reader :findings

      def initialize(findings)
        @findings = findings.freeze
      end

      def ready? = findings.empty?

      def to_h
        {
          schema_version: 1,
          status: ready? ? "ready" : "blocked",
          ready: ready?,
          findings: findings
        }
      end
    end
  end
end

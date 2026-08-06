# frozen_string_literal: true

require "test_helper"

module Releases
  class PullRequestValidatorTest < ActiveSupport::TestCase
    test "requires a matching fragment for release-relevant changes" do
      report = PullRequestValidator.new(
        changed_paths: [ "app/models/widget.rb" ],
        pull_request_number: 57
      ).call

      assert_not report.ready?
      assert_includes report.findings.pluck(:code), "change_fragment_missing"
      assert_includes report.findings.pluck(:code), "change_fragment_pr_mismatch"
    end

    test "allows documentation and test-only changes without a fragment" do
      report = PullRequestValidator.new(
        changed_paths: [ "docs/example.md", "test/models/example_test.rb" ],
        pull_request_number: 57
      ).call

      assert report.ready?
    end

    test "accepts a valid fragment matching the pull request" do
      Dir.mktmpdir do |directory|
        FileUtils.mkdir_p(File.join(directory, "changes"))
        FileUtils.cp(
          release_fragment_fixture("57-release-fragment-ci.yml"),
          File.join(directory, "changes/57-release-fragment-ci.yml")
        )
        report = Dir.chdir(directory) do
          PullRequestValidator.new(
            changed_paths: [
              "app/services/releases/pull_request_validator.rb",
              "changes/57-release-fragment-ci.yml"
            ],
            pull_request_number: 57
          ).call
        end

        assert report.ready?, report.findings.inspect
      end
    end

    test "requires explicit migration impact" do
      report = PullRequestValidator.new(
        changed_paths: [
          "db/migrate/20260728000000_change_widgets.rb",
          "changes/57-release-fragment-ci.yml"
        ],
        pull_request_number: 57
      ).call

      assert_includes report.findings.pluck(:code), "migration_impact_missing"
    end

    test "accepts a bounded deterministic release preparation" do
      report = PullRequestValidator.new(
        changed_paths: [
          "VERSION",
          "CHANGELOG.md",
          "changes/archive/0.9.0/58-release-notes.yml",
          "docs/releases/0.9.0/release-metadata.json"
        ],
        pull_request_number: 99
      ).call

      assert report.ready?, report.findings.inspect
    end

    test "does not exempt application changes in a release preparation" do
      report = PullRequestValidator.new(
        changed_paths: [
          "VERSION",
          "app/models/widget.rb",
          "changes/archive/0.9.0/58-release-notes.yml",
          "docs/releases/0.9.0/release-metadata.json"
        ],
        pull_request_number: 99
      ).call

      assert_includes report.findings.pluck(:code), "change_fragment_missing"
    end

    private

    def release_fragment_fixture(name)
      path = Rails.root.glob("changes/**/#{name}").first
      raise "missing release test fixture #{name}" unless path

      path
    end
  end
end

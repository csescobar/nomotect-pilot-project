# frozen_string_literal: true

require "test_helper"

module ApplicationLayer
  class CertificationTest < ActiveSupport::TestCase
    FakeRepository = Data.define(:paths) do
      def commit_exists?(_commit) = true
      def changed_paths(_baseline, _source) = paths
    end

    test "binds evidence to commits and derives the protected review boundary" do
      report = Certification.new(
        source_commit: "a" * 40,
        baseline_commit: "b" * 40,
        repository: FakeRepository.new([ "application/config/roles.rb", "app/lib/application_roles.rb" ])
      ).call

      assert_equal "a" * 40, report.fetch("source_commit")
      assert_equal "b" * 40, report.fetch("baseline_commit")
      assert report.fetch("protected_core_modified")
      assert_equal [ "app/lib/application_roles.rb" ], report.fetch("protected_core_paths")
      assert_equal "architecture_review_required", report.fetch("review_boundary")
      assert_equal Certification::REGISTRATION_FILES, report.fetch("loaded_registration_files")
    end

    test "reports an application-only adoption without protected changes" do
      report = Certification.new(
        source_commit: "c" * 40,
        baseline_commit: "d" * 40,
        repository: FakeRepository.new([ "application/config/grids.rb" ])
      ).call

      assert_not report.fetch("protected_core_modified")
      assert_empty report.fetch("protected_core_paths")
      assert_equal "application_only", report.fetch("review_boundary")
    end

    test "rejects unavailable commits and missing registration load evidence" do
      unavailable = Data.define(:paths) do
        def commit_exists?(_commit) = false
      end.new([])
      assert_raises(Certification::InvalidCertification) do
        Certification.new(source_commit: "e" * 40, baseline_commit: "f" * 40, repository: unavailable).call
      end

      previous = Rails.application.config.x.application_registration_files
      Rails.application.config.x.application_registration_files = []
      assert_raises(Certification::InvalidCertification) do
        Certification.new(
          source_commit: "1" * 40,
          baseline_commit: "2" * 40,
          repository: FakeRepository.new([])
        ).call
      end
    ensure
      Rails.application.config.x.application_registration_files = previous
    end
  end
end

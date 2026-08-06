# frozen_string_literal: true

require "test_helper"

module Epic10
  class RepresentativeApplicationCertificationTest < ActiveSupport::TestCase
    test "certifies every Phase 2 journey without private context or publication" do
      report = RepresentativeApplicationCertification.new(source_commit: "a" * 40).call

      assert_equal "passed", report.fetch("status")
      assert_equal 2, report.fetch("phase")
      assert_equal %w[foundation design_i18n_grid domain_services multitenant_extension], report.fetch("journeys")
      assert report.fetch("public_contracts_only")
      assert_not report.fetch("private_maintainer_context_required")
      assert_not report.dig("publication", "allowed")
    end

    test "rejects an invalid commit and missing journey evidence" do
      assert_raises(RepresentativeApplicationCertification::InvalidCertification) do
        RepresentativeApplicationCertification.new(source_commit: "main").call
      end

      Dir.mktmpdir do |root|
        FileUtils.mkdir_p(Pathname(root).join("config/epic_10"))
        FileUtils.cp(Rails.root.join("config/epic_10/representative-application.yml"), Pathname(root).join("config/epic_10"))
        error = assert_raises(RepresentativeApplicationCertification::InvalidCertification) do
          RepresentativeApplicationCertification.new(source_commit: "b" * 40, root: root).call
        end
        assert_includes error.message, "No such file"
      end
    end
  end
end

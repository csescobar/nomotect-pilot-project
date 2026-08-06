# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module Epic10
  class FunctionalFrameworkCertificationTest < ActiveSupport::TestCase
    SOURCE_COMMIT = "a" * 40

    test "certifies every integrated public functional area and negative path" do
      report = FunctionalFrameworkCertification.new(source_commit: SOURCE_COMMIT).call

      assert_equal "passed", report.fetch("status")
      assert_equal 4, report.fetch("phase")
      assert_equal FunctionalFrameworkCertification::EXPECTED_AREAS, report.fetch("areas").pluck("id")
      assert report.fetch("areas").all? { |area| area["status"] == "passed" }
      assert report.fetch("areas").all? { |area| area["negative_evidence"].present? }
      assert_equal "resolved", report.fetch("findings").first.fetch("status")
      assert report.fetch("credential_free")
      assert_equal false, report.dig("publication", "allowed")
    end

    test "rejects missing negative evidence fail closed" do
      data = YAML.safe_load_file(Rails.root.join("config/epic_10/functional-framework.yml"))
      data.fetch("required_areas").first.delete("negative_evidence")

      Dir.mktmpdir do |directory|
        path = File.join(directory, "functional-framework.yml")
        File.write(path, data.to_yaml)

        assert_raises(FunctionalFrameworkCertification::InvalidCertification) do
          FunctionalFrameworkCertification.new(source_commit: SOURCE_COMMIT, path: path).call
        end
      end
    end

    test "rejects invalid source commit" do
      assert_raises(FunctionalFrameworkCertification::InvalidCertification) do
        FunctionalFrameworkCertification.new(source_commit: "main").call
      end
    end
  end
end

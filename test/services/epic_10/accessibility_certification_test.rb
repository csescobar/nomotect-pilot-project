# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module Epic10
  class AccessibilityCertificationTest < ActiveSupport::TestCase
    SOURCE_COMMIT = "a" * 40

    test "certifies automated accessibility while preserving human review" do
      report = AccessibilityCertification.new(source_commit: SOURCE_COMMIT).call

      assert_equal "automated_pass", report.fetch("status")
      assert report.fetch("checks").all? { |check| check["status"] == "passed" }
      assert_equal 0, report.dig("thresholds", "critical_violations")
      assert_equal true, report.dig("manual_screen_reader_review", "required")
      assert_equal false, report.dig("manual_screen_reader_review", "approved")
      assert_equal false, report.fetch("stable_release_ready")
      assert_equal false, report.dig("publication", "allowed")
    end

    test "rejects keyboard blockers fail closed" do
      data = YAML.safe_load_file(Rails.root.join("config/epic_10/accessibility.yml"))
      data.fetch("thresholds")["keyboard_blockers"] = 1
      Dir.mktmpdir do |directory|
        path = File.join(directory, "accessibility.yml")
        File.write(path, data.to_yaml)
        assert_raises(AccessibilityCertification::InvalidCertification) do
          AccessibilityCertification.new(source_commit: SOURCE_COMMIT, path: path).call
        end
      end
    end
  end
end

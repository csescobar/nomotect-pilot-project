# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

module Epic10
  class RcUpgradeCertificationTest < ActiveSupport::TestCase
    test "certifies interruption resume compatibility backup and recovery" do
      report = RcUpgradeCertification.new(clock: -> { Time.iso8601("2026-07-31T00:00:00Z") }).call

      assert_equal "passed", report.fetch("status")
      assert_equal 3, report.fetch("phase")
      assert_equal "running", report.dig("interruption", "status")
      assert_equal "retryable", report.dig("interruption", "classification")
      assert_equal "completed", report.dig("resume", "status")
      assert report.fetch("backup_evidence_required")
      assert report.fetch("incompatible_inputs_rejected")
      assert report.fetch("credential_free")
      assert_equal false, report.dig("publication", "allowed")
    end

    test "rejects incomplete upgrade evidence fail closed" do
      Dir.mktmpdir do |directory|
        source = Rails.root.join("test/support/epic_10/upgrades")
        FileUtils.cp_r(Dir[source.join("*")], directory)
        path = File.join(directory, "rc.1-to-rc.2.yml")
        data = YAML.safe_load_file(path)
        data.fetch("backup")["required"] = false
        File.write(path, data.to_yaml)

        assert_raises(RcUpgradeCertification::InvalidCertification) do
          RcUpgradeCertification.new(root: directory).call
        end
      end
    end
  end
end

# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module Epic10
  class OperationalResilienceCertificationTest < ActiveSupport::TestCase
    SOURCE_COMMIT = "a" * 40

    test "certifies restart replacement degradation backup and recovery" do
      report = OperationalResilienceCertification.new(source_commit: SOURCE_COMMIT).call

      assert_equal "passed", report.fetch("status")
      assert_equal OperationalResilienceCertification::REQUIRED_SCENARIOS, report.fetch("scenarios").pluck("id")
      assert report.fetch("scenarios").all? { |scenario| scenario["recovery"] == "verified" }
      assert_equal OperationalResilienceCertification::REQUIRED_EVIDENCE, report.fetch("required_evidence")
      assert report.fetch("credential_free")
      assert_equal false, report.dig("publication", "allowed")
    end

    test "rejects unverified recovery fail closed" do
      data = YAML.safe_load_file(Rails.root.join("config/epic_10/operational-resilience.yml"))
      data.fetch("scenarios").first["recovery"] = "unknown"
      Dir.mktmpdir do |directory|
        path = File.join(directory, "operational-resilience.yml")
        File.write(path, data.to_yaml)
        assert_raises(OperationalResilienceCertification::InvalidCertification) do
          OperationalResilienceCertification.new(source_commit: SOURCE_COMMIT, path: path).call
        end
      end
    end
  end
end

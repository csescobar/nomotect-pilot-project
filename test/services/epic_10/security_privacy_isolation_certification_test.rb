# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module Epic10
  class SecurityPrivacyIsolationCertificationTest < ActiveSupport::TestCase
    SOURCE_COMMIT = "a" * 40

    test "certifies security privacy and tenant isolation thresholds" do
      report = SecurityPrivacyIsolationCertification.new(source_commit: SOURCE_COMMIT).call

      assert_equal "passed", report.fetch("status")
      assert report.fetch("certifications").all? { |item| item["status"] == "passed" }
      assert report.fetch("thresholds").values.all?(&:zero?)
      assert_equal "resolved", report.fetch("findings").first.fetch("status")
      assert report.fetch("credential_free")
      assert_equal false, report.dig("publication", "allowed")
    end

    test "rejects cross tenant leakage fail closed" do
      data = YAML.safe_load_file(Rails.root.join("config/epic_10/security-privacy-isolation.yml"))
      data.fetch("thresholds")["cross_tenant_leaks"] = 1
      Dir.mktmpdir do |directory|
        path = File.join(directory, "security-privacy-isolation.yml")
        File.write(path, data.to_yaml)
        assert_raises(SecurityPrivacyIsolationCertification::InvalidCertification) do
          SecurityPrivacyIsolationCertification.new(source_commit: SOURCE_COMMIT, path: path).call
        end
      end
    end
  end
end

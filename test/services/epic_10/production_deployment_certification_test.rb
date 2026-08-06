# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module Epic10
  class ProductionDeploymentCertificationTest < ActiveSupport::TestCase
    SOURCE_COMMIT = "a" * 40

    test "certifies production-like deployment services and evidence" do
      report = ProductionDeploymentCertification.new(source_commit: SOURCE_COMMIT).call

      assert_equal "passed", report.fetch("status")
      assert_equal 5, report.fetch("phase")
      assert_equal "production_like", report.fetch("profile")
      assert report.fetch("checks").all? { |check| check["status"] == "passed" }
      assert report.fetch("credential_free")
      assert_equal false, report.dig("publication", "allowed")
    end

    test "rejects incomplete deployment observation fail closed" do
      data = YAML.safe_load_file(Rails.root.join("config/epic_10/production-deployment.yml"))
      data.fetch("observations")["persistent_files"] = "missing"

      Dir.mktmpdir do |directory|
        path = File.join(directory, "production-deployment.yml")
        File.write(path, data.to_yaml)
        assert_raises(ProductionDeploymentCertification::InvalidCertification) do
          ProductionDeploymentCertification.new(source_commit: SOURCE_COMMIT, path: path).call
        end
      end
    end
  end
end

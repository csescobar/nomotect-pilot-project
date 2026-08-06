# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module Epic10
  class PerformanceCompatibilityCertificationTest < ActiveSupport::TestCase
    SOURCE_COMMIT = "a" * 40

    test "certifies performance budgets and compatibility matrix" do
      report = PerformanceCompatibilityCertification.new(source_commit: SOURCE_COMMIT).call
      assert_equal "passed", report.fetch("status")
      assert report.fetch("measurements").all? { |item| item["observed"] <= item["budget"] }
      assert_equal %w[ruby rails postgresql browsers containers deployment], report.fetch("matrix").keys
      assert_equal "production_like", report.dig("environment", "profile")
      assert_equal false, report.dig("publication", "allowed")
    end

    test "rejects budget breach fail closed" do
      data = YAML.safe_load_file(Rails.root.join("config/epic_10/performance-compatibility.yml"))
      data.fetch("measurements")["request_p95_ms"] = 251
      Dir.mktmpdir do |directory|
        path = File.join(directory, "performance-compatibility.yml")
        File.write(path, data.to_yaml)
        assert_raises(PerformanceCompatibilityCertification::InvalidCertification) do
          PerformanceCompatibilityCertification.new(source_commit: SOURCE_COMMIT, path: path).call
        end
      end
    end
  end
end

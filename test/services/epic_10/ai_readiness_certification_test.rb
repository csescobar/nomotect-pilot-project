# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module Epic10
  class AiReadinessCertificationTest < ActiveSupport::TestCase
    SOURCE_COMMIT = "a" * 40

    test "certifies a bounded repository-native contributor journey" do
      report = AiReadinessCertification.new(source_commit: SOURCE_COMMIT).call

      assert_equal "passed", report.fetch("status")
      assert_equal "unfamiliar", report.dig("journey", "contributor_profile")
      assert_equal 0, report.dig("evidence", "undocumented_context_steps")
      assert_equal true, report.dig("evidence", "bounded_change_completion")
      assert_equal false, report.dig("publication", "allowed")
    end

    test "rejects undocumented contributor context fail closed" do
      data = YAML.safe_load_file(Rails.root.join("config/epic_10/ai-readiness.yml"))
      data.fetch("journey").fetch("steps").first["documented_context"] = false

      Dir.mktmpdir do |directory|
        path = File.join(directory, "ai-readiness.yml")
        File.write(path, data.to_yaml)

        assert_raises(AiReadinessCertification::InvalidCertification) do
          AiReadinessCertification.new(source_commit: SOURCE_COMMIT, path: path).call
        end
      end
    end
  end
end

# frozen_string_literal: true

require "test_helper"

module Epic10
  class ReleaseBaselineTest < ActiveSupport::TestCase
    test "loads the governed runtime matrix and every quality category" do
      baseline = ReleaseBaseline.load(Rails.root.join("config/epic_10/release-baseline.yml"))

      assert_equal "4.0.5", baseline.runtime("ruby").fetch("version")
      assert_equal "8.1.3.1", baseline.runtime("rails").fetch("version")
      assert_equal "18", baseline.runtime("postgresql").fetch("version")
      assert_equal ReleaseBaseline::THRESHOLD_CATEGORIES.sort, baseline.data.fetch("thresholds").keys.sort
      assert_predicate baseline.data, :frozen?
    end

    test "rejects missing runtime and quality categories" do
      data = baseline_data
      data["runtimes"].reject! { |runtime| runtime.fetch("name") == "postgresql" }

      error = assert_raises(ReleaseBaseline::InvalidBaseline) { ReleaseBaseline.new(data) }
      assert_includes error.message, "missing required runtimes"

      data = baseline_data
      data["thresholds"].delete("privacy")
      assert_raises(ReleaseBaseline::InvalidBaseline) { ReleaseBaseline.new(data) }
    end

    test "rejects duplicate metrics unknown fields and invalid manual support" do
      data = baseline_data
      data["thresholds"]["security"] << data["thresholds"]["security"].first.dup
      assert_raises(ReleaseBaseline::InvalidBaseline) { ReleaseBaseline.new(data) }

      data = baseline_data
      data["browsers"].first["unexpected"] = true
      assert_raises(ReleaseBaseline::InvalidBaseline) { ReleaseBaseline.new(data) }

      data = baseline_data
      data["browsers"].first["support_level"] = "manual"
      data["browsers"].first["manual_required"] = false
      assert_raises(ReleaseBaseline::InvalidBaseline) { ReleaseBaseline.new(data) }
    end

    test "requires equality for boolean release gates" do
      data = baseline_data
      metric = data["thresholds"]["accessibility"].first
      metric["target"] = true
      metric["comparator"] = "gte"

      error = assert_raises(ReleaseBaseline::InvalidBaseline) { ReleaseBaseline.new(data) }
      assert_includes error.message, "boolean target requires eq"
    end

    private

    def baseline_data
      YAML.safe_load_file(Rails.root.join("config/epic_10/release-baseline.yml"), aliases: false)
    end
  end
end

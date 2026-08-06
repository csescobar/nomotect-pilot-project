# frozen_string_literal: true

require "test_helper"

module Epic10
  class RcPreparationTest < ActiveSupport::TestCase
    COMMIT = "a" * 40

    test "creates a deterministic review-only RC plan" do
      preparation = RcPreparation.new(target_version: "1.0.0-rc.1", source_commit: COMMIT)

      first = preparation.plan
      second = preparation.plan

      assert_equal first, second
      assert_equal "review_required", first.fetch(:status)
      assert_equal "v1.0.0-rc.1", first.fetch(:tag)
      assert_equal COMMIT, first.fetch(:source_commit)
      assert_equal false, first.dig(:approval, :approved)
      assert_equal false, first.dig(:publication, :allowed)
      assert_equal RcPreparation::REQUIRED_EVIDENCE, first.fetch(:required_evidence)
    end

    test "rejects stable arbitrary and malformed targets" do
      %w[1.0.0 1.0.0-beta.1 0.10.0-rc.1 1.0.0-rc.0].each do |target|
        preparation = RcPreparation.new(target_version: target, source_commit: COMMIT)
        assert_includes preparation.validate, "target version must be an Epic 10 release candidate"
      end
    end

    test "requires a full source commit and the pre-stable source version" do
      preparation = RcPreparation.new(target_version: "1.0.0-rc.1", source_commit: "abc123")
      assert_includes preparation.validate, "source commit must be a full lowercase Git SHA"

      Dir.mktmpdir do |directory|
        File.write(File.join(directory, "VERSION"), "1.0.0\n")
        File.write(File.join(directory, "CHANGELOG.md"), "# Changelog\n")
        FileUtils.mkdir_p(File.join(directory, "config/epic_10"))
        FileUtils.cp(
          Rails.root.join("config/epic_10/release-baseline.yml"),
          File.join(directory, "config/epic_10/release-baseline.yml")
        )
        preparation = RcPreparation.new(target_version: "1.0.0-rc.1", source_commit: COMMIT, root: directory)

        assert_includes preparation.validate, "VERSION must remain 0.9.0 during RC planning"
      end
    end

    test "fails closed when governed inputs are missing" do
      Dir.mktmpdir do |directory|
        File.write(File.join(directory, "VERSION"), "0.9.0\n")
        preparation = RcPreparation.new(target_version: "1.0.0-rc.1", source_commit: COMMIT, root: directory)

        error = assert_raises(RcPreparation::InvalidPreparation) { preparation.plan }
        assert_includes error.message, "required RC planning input is missing"
      end
    end
  end
end

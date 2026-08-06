# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

module Epic10
  class RcUpgradeFixtureTest < ActiveSupport::TestCase
    test "certifies representative application candidate fixtures and manifest" do
      report = RcUpgradeFixture.new.call

      assert_equal "passed", report.fetch("status")
      assert_equal "1.0.0-rc.1", report.fetch("source_candidate")
      assert_equal "1.0.0-rc.2", report.fetch("target_candidate")
      assert report.fetch("backup_required")
      assert_equal "verify-target", report.fetch("operation_ids").last
      assert report.fetch("credential_free")
    end

    test "rejects incomplete candidate evidence fail closed" do
      Dir.mktmpdir do |directory|
        source = Rails.root.join("test/support/epic_10/upgrades")
        FileUtils.cp_r(Dir[source.join("*")], directory)
        path = File.join(directory, "representative-app-rc.1.yml")
        data = YAML.safe_load_file(path)
        data.fetch("evidence")["credential_free"] = false
        File.write(path, data.to_yaml)

        assert_raises(RcUpgradeFixture::InvalidFixture) do
          RcUpgradeFixture.new(root: directory).call
        end
      end
    end
  end
end

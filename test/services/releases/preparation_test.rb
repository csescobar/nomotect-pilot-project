# frozen_string_literal: true

require "test_helper"

module Releases
  class PreparationTest < ActiveSupport::TestCase
    test "plans a minor release without changing files" do
      Dir.mktmpdir do |directory|
        copy_release_inputs(directory)
        preparation = Preparation.new(target_version: "0.9.0", root: directory)

        assert_equal "minor", preparation.plan.fetch(:release_impact)
        assert_equal "0.8.0\n", File.read(File.join(directory, "VERSION"))
      end
    end

    test "applies a deterministic release preparation" do
      Dir.mktmpdir do |directory|
        copy_release_inputs(directory)
        result = Preparation.new(target_version: "0.9.0", root: directory).apply!

        assert_equal "0.9.0\n", File.read(File.join(directory, "VERSION"))
        assert File.exist?(File.join(directory, "changes/archive/0.9.0/58-release-notes.yml"))
        assert File.exist?(File.join(directory, "docs/releases/0.9.0/release-metadata.json"))
        assert_includes File.read(File.join(directory, "CHANGELOG.md")), "## 0.9.0"
        assert_equal "0.9.0", result.fetch(:target_version)
        assert_empty NotesGenerator.new(root: directory, current_version: "0.9.0").validate
      end
    end

    test "rejects a target below accumulated release impact" do
      Dir.mktmpdir do |directory|
        copy_release_inputs(directory)
        preparation = Preparation.new(target_version: "0.8.1", root: directory)

        assert_includes preparation.validate, "target version does not satisfy minor release impact"
      end
    end

    private

    def copy_release_inputs(directory)
      FileUtils.mkdir_p(File.join(directory, "changes"))
      File.write(File.join(directory, "VERSION"), "0.8.0\n")
      %w[56-release-foundation.yml 58-release-notes.yml].each do |name|
        source = Rails.root.glob("changes/**/#{name}").first
        raise "missing release test fixture #{name}" unless source

        FileUtils.cp(source, File.join(directory, "changes", name))
      end
    end
  end
end

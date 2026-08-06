# frozen_string_literal: true

require "test_helper"

module Releases
  class NotesGeneratorTest < ActiveSupport::TestCase
    test "renders deterministic notes from sorted fragments" do
      generator = NotesGenerator.new(
        fragments: release_test_fragments.reverse,
        current_version: "0.8.0"
      )

      notes = generator.release_notes

      assert_operator notes.index("56-release-foundation"), :<, notes.index("58-release-notes")
      assert_includes notes, "Required release impact: `minor`"
      assert_includes notes, "`change-fragment`"
    end

    test "committed generated documents are current" do
      assert_empty NotesGenerator.new.validate
    end

    test "reports stale output without replacing it" do
      Dir.mktmpdir do |directory|
        generator = NotesGenerator.new(
          fragments: release_test_fragments,
          current_version: "0.8.0",
          root: directory
        )
        generator.write!
        File.write(File.join(directory, "CHANGELOG.md"), "stale")

        assert_includes generator.validate, "stale generated release document: CHANGELOG.md"
      end
    end

    private

    def release_test_fragments
      %w[56-release-foundation.yml 58-release-notes.yml].map do |name|
        path = Rails.root.glob("changes/**/#{name}").first
        raise "missing release test fixture #{name}" unless path

        ChangeFragment.load(path)
      end
    end
  end
end

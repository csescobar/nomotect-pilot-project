# frozen_string_literal: true

require "test_helper"

module Releases
  class ChangeFragmentTest < ActiveSupport::TestCase
    test "loads strict release impact and cross-cutting assessments" do
      fragment = ChangeFragment.new(fragment_data)

      assert_equal "release-foundation", fragment.id
      assert_equal "minor", fragment.release_impact
      assert_equal %w[platform-version change-fragment], fragment.contracts
    end

    test "rejects action requirements without operator notes" do
      data = fragment_data
      data["migration"] = { "required" => true, "notes" => nil }

      error = assert_raises(ChangeFragment::InvalidFragment) { ChangeFragment.new(data) }
      assert_includes error.message, "migration notes"
    end

    test "rejects duplicate catalog identifiers" do
      Dir.mktmpdir do |directory|
        2.times do |index|
          File.write(
            File.join(directory, "#{index}.yml"),
            YAML.dump(fragment_data)
          )
        end

        assert_raises(ChangeCatalog::DuplicateFragment) do
          ChangeCatalog.new(path: directory).fragments
        end
      end
    end

    private

    def fragment_data
      {
        "schema_version" => 1,
        "id" => "release-foundation",
        "category" => "feature",
        "summary" => "Establish release metadata.",
        "release_impact" => "minor",
        "contracts" => %w[platform-version change-fragment],
        "migration" => { "required" => false, "notes" => nil },
        "upgrade" => { "required" => false, "notes" => nil },
        "security" => { "impact" => "reviewed", "notes" => "No credential data." },
        "privacy" => { "impact" => "none", "notes" => nil },
        "accessibility" => { "impact" => "none", "notes" => nil }
      }
    end
  end
end

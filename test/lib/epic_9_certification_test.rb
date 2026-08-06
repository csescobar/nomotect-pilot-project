# frozen_string_literal: true

require "test_helper"
require_relative "../../lib/epic_9/certification"

class Epic9CertificationTest < ActiveSupport::TestCase
  test "certifies the complete repository Epic 9 evidence" do
    result = certification.certify

    assert_equal "certified", result.fetch(:status)
    assert_equal false, result.fetch(:stable_release_authorized)
    assert_empty result.fetch(:findings)
  end

  test "rejects missing failed or undocumented gates" do
    catalog = {
      "schema_version" => 1,
      "epic" => 9,
      "status" => "certified",
      "stable_release_authorized" => false,
      "gates" => [
        {
          "id" => "installation",
          "status" => "failed",
          "evidence" => ""
        }
      ]
    }

    result = Epic9::Certification.new(repository_path: Rails.root, catalog: catalog).certify

    assert_equal "not_certified", result.fetch(:status)
    assert result.fetch(:findings).any? { |finding| finding.include?("missing gates") }
    assert_includes result.fetch(:findings), "installation must be passed"
    assert_includes result.fetch(:findings), "installation must include evidence"
  end

  private

  def certification
    Epic9::Certification.new(
      repository_path: Rails.root,
      catalog_path: Rails.root.join("config/epic_9/certification.yml")
    )
  end
end

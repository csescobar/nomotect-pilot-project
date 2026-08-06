# frozen_string_literal: true

require "test_helper"

class CompatibilityLifecycleDocumentationTest < ActiveSupport::TestCase
  POLICY = Rails.root.join("docs/operators/compatibility-and-lifecycle.md")
  REQUIRED_SECTIONS = [
    "Supported environment matrix",
    "Contract compatibility matrix",
    "Release lifecycle",
    "Deprecation policy",
    "Upgrade and extension lifecycle",
    "Architecture diagram",
    "Lifecycle state machine",
    "Upgrade sequence",
    "Security boundary",
    "Recovery flow",
    "Ownership and review"
  ].freeze

  test "publishes compatibility and lifecycle policy sections" do
    content = POLICY.read

    REQUIRED_SECTIONS.each do |section|
      assert_includes content, "## #{section}"
    end
    assert_equal 5, content.scan(/```mermaid/).size
  end

  test "keeps pre-stable and fail-closed boundaries explicit" do
    content = POLICY.read

    assert_includes content, "Completing Epic 9 does not authorize"
    assert_includes content, "Unknown versions"
    assert_includes content, "Extensions outside their declared compatibility"
    assert_includes content, "forward recovery"
  end
end

# frozen_string_literal: true

require "test_helper"

class CleanStarterOnboardingTest < ActiveSupport::TestCase
  test "setup reports an intentional missing pg_isready path" do
    setup = Rails.root.join("bin/setup").read

    assert_includes setup, "pg_isready is not installed"
    assert_includes setup, "Database provisioning will still attempt"
  end

  test "grid documentation names only registered types" do
    documentation = Rails.root.join("docs/grid/architecture.md").read

    GridEngine::Types.registry.keys.each { |type| assert_includes documentation, "- #{type}" }
    assert_includes documentation, "are not registered types"
  end

  test "controlled onboarding remains distinct from Phase 8" do
    documentation = Rails.root.join("docs/adoption/clean-starter-onboarding.md").read

    assert_includes documentation, "Public GitHub Release download validation belongs to Phase 8"
    assert_includes documentation, "It is not the independent Phase 8 adoption pilot"
  end
end

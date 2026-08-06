# frozen_string_literal: true

require "test_helper"
require "yaml"

class DistributionObservationWorkflowTest < ActiveSupport::TestCase
  test "produces credential-free verification input with read-only permissions" do
    workflow = YAML.safe_load_file(
      Rails.root.join(".github/workflows/observe-distribution.yml"),
      aliases: true
    )

    assert_equal(
      { "actions" => "read", "contents" => "read", "packages" => "read" },
      workflow.fetch("permissions")
    )
    serialized = workflow.to_json
    assert_includes serialized, "distribution-verification-input"
    assert_includes serialized, "bin/distribution-observe"
    refute_includes serialized, "packages: write"
    refute_includes serialized, "contents: write"
  end

  test "verification accepts evidence only from the observation workflow" do
    workflow = Rails.root.join(".github/workflows/verify-distribution.yml").read

    assert_includes workflow, 'test "$(jq -r .name <<<"$run_json")" = "Observe Distribution"'
    assert_includes workflow, 'test "$(jq -r .event <<<"$run_json")" = "workflow_dispatch"'
  end
end

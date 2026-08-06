# frozen_string_literal: true

require "test_helper"
require_relative "../../../lib/repository_intelligence"
require_relative "../../../lib/repository_intelligence/platform"

module Releases
  class ReleaseReadinessPlaybookTest < ActiveSupport::TestCase
    test "executes the bounded release readiness playbook" do
      playbook = YAML.safe_load_file(
        Rails.root.join("config/ai/playbooks/release_readiness.yml"),
        aliases: false
      )
      contract = YAML.safe_load_file(
        Rails.root.join("config/ai/contracts/releases.yml"),
        aliases: false
      )
      RepositoryIntelligence.configure(
        graph: RepositoryIntelligence::GovernanceGraph.new,
        contracts: [ contract ],
        playbooks: [ playbook ],
        manifest: { files: [ { path: "VERSION" } ] },
        readiness: { status: "ready" },
        validator: -> { [] }
      )

      assert_empty RepositoryIntelligence.validate_playbook("release_readiness")
      execution = RepositoryIntelligence.execute_playbook(
        "release_readiness",
        inputs: { "target_version" => "0.9.0" }
      )

      assert_equal "completed", execution.status
      assert execution.evidence.fetch(:completion_gate)
    end
  end
end

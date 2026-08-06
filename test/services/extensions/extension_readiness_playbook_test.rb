# frozen_string_literal: true

require "test_helper"
require_relative "../../../lib/repository_intelligence"
require_relative "../../../lib/repository_intelligence/platform"

module Extensions
  class ExtensionReadinessPlaybookTest < ActiveSupport::TestCase
    test "executes the bounded extension readiness playbook" do
      playbook = YAML.safe_load_file(
        Rails.root.join("config/ai/playbooks/extension_readiness.yml"),
        aliases: false
      )
      contract = YAML.safe_load_file(
        Rails.root.join("config/ai/contracts/extensions.yml"),
        aliases: false
      )
      RepositoryIntelligence.configure(
        graph: RepositoryIntelligence::GovernanceGraph.new,
        contracts: [ contract ],
        playbooks: [ playbook ],
        manifest: {
          files: [
            { path: "docs/contracts/extension-manifest.schema.json" },
            { path: "test/support/extension_fixtures/certification-audit/platform-extension.yml" },
            { path: "docs/extensions/certification.md" }
          ]
        },
        readiness: { status: "ready" },
        validator: -> { [] }
      )

      assert_empty RepositoryIntelligence.validate_playbook("extension_readiness")
      execution = RepositoryIntelligence.execute_playbook(
        "extension_readiness",
        inputs: { "platform_version" => "0.9.0" }
      )

      assert_equal "completed", execution.status
      assert execution.evidence.fetch(:completion_gate)
      assert_includes contract.fetch("owns"), "extension_certification_matrix"
      assert_includes contract.fetch("required_tests"), "extension_framework_certification_test"
    end
  end
end

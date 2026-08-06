# frozen_string_literal: true

require "test_helper"
require_relative "../../lib/repository_intelligence"
require_relative "../../lib/repository_intelligence/platform"
require_relative "../../lib/repository_intelligence/mcp_server"
require_relative "../../lib/repository_intelligence/mcp_playbook_tools"

class RepositoryIntelligencePlaybookExecutorTest < ActiveSupport::TestCase
  def setup
    graph = RepositoryIntelligence::GovernanceGraph.new
    graph.add_node(RepositoryIntelligence::Node.new(
      id: "model:Customer", type: "model", name: "Customer", path: "app/models/customer.rb", properties: {}
    ))
    @playbook = {
      "id" => "verify-customer",
      "version" => 1,
      "title" => "Verify customer",
      "inputs" => [ "target" ],
      "steps" => [
        { "id" => "describe", "tool" => "repository.describe", "args" => { "id" => "{{inputs.target}}" } },
        { "id" => "validate", "tool" => "repository.validate", "args" => {} }
      ],
      "completion_gate" => [ "all_steps_pass", "validation_passes" ]
    }
    RepositoryIntelligence.configure(
      graph:, contracts: [], playbooks: [ @playbook ], manifest: { files: [] },
      readiness: { status: "ready" }, validator: -> { [] }
    )
  end

  test "validates and executes bounded playbook steps with evidence" do
    events = []
    RepositoryIntelligence.subscribe(:playbook_completed) { |event| events << event }

    assert_empty RepositoryIntelligence.validate_playbook("verify-customer")
    execution = RepositoryIntelligence.execute_playbook("verify-customer", inputs: { "target" => "Customer" })

    assert_equal "completed", execution.status
    assert_equal 2, execution.steps.size
    assert_equal 2, execution.evidence.fetch(:successful_steps)
    assert execution.evidence.fetch(:completion_gate)
    assert_equal execution.id, RepositoryIntelligence.playbook_execution(execution.id).id
    assert_equal 1, events.size
  end

  test "rejects arbitrary operations" do
    invalid = @playbook.merge(
      "id" => "unsafe", "steps" => [ { "id" => "shell", "tool" => "shell.exec", "args" => {} } ]
    )

    assert_includes RepositoryIntelligence.validate_playbook(invalid), "step 1 uses unknown operation shell.exec"
    assert_raises(ArgumentError) { RepositoryIntelligence.execute_playbook(invalid) }
  end

  test "exposes validation and execution through MCP" do
    server = RepositoryIntelligence::McpServer.new(
      intelligence: RepositoryIntelligence, playbooks: [ @playbook ], input: StringIO.new, output: StringIO.new
    )
    validated = server.handle(
      "jsonrpc" => "2.0", "id" => 1, "method" => "tools/call",
      "params" => { "name" => "validate_playbook", "arguments" => { "id" => "verify-customer" } }
    )
    executed = server.handle(
      "jsonrpc" => "2.0", "id" => 2, "method" => "tools/call",
      "params" => {
        "name" => "execute_playbook", "arguments" => { "id" => "verify-customer", "inputs" => { "target" => "Customer" } }
      }
    )

    assert_equal "[]", validated.dig(:result, :content, 0, :text)
    assert_includes executed.dig(:result, :content, 0, :text), '"status": "completed"'
  end
end

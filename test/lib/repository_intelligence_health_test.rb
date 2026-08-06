# frozen_string_literal: true

require "test_helper"
require "stringio"
require_relative "../../lib/repository_intelligence"
require_relative "../../lib/repository_intelligence/platform"
require_relative "../../lib/repository_intelligence/mcp_server"
require_relative "../../lib/repository_intelligence/mcp_health_tools"

class RepositoryIntelligenceHealthTest < ActiveSupport::TestCase
  def setup
    graph = RepositoryIntelligence::GovernanceGraph.new
    graph.add_node(RepositoryIntelligence::Node.new(
      id: "model:Customer", type: "model", name: "Customer", path: "app/models/customer.rb", properties: {}
    ))
    graph.add_node(RepositoryIntelligence::Node.new(
      id: "document:Customer", type: "document", name: "Customer", path: "docs/customer.md", properties: {}
    ))
    graph.add_edge(RepositoryIntelligence::Edge.new(
      from: "model:Customer", to: "document:Customer", type: "DOCUMENTED_BY", properties: {}
    ))
    contracts = [ {
      "id" => "customer", "version" => 1, "owns" => [ "Customer" ],
      "invariants" => [ "security controls", "privacy controls", "tenant boundary" ]
    } ]
    playbooks = [ {
      "id" => "review", "version" => 1, "title" => "Review", "steps" => [], "completion_gate" => []
    } ]
    RepositoryIntelligence.configure(
      graph:, contracts:, playbooks:, manifest: { files: [] }, readiness: { status: "ready" },
      provider_status: { available: true, provider: "fixture" }, artifact_validator: -> { [] }
    )
  end

  test "aggregates validators into a healthy repository report" do
    health = RepositoryIntelligence.health

    assert_equal "healthy", health.fetch(:status)
    assert_equal 100, health.fetch(:score)
    assert_includes RepositoryIntelligence.validator_list, :graph_integrity
    assert_includes RepositoryIntelligence.validator_list, :documentation_governance
    assert_empty RepositoryIntelligence.remediation_plan
  end

  test "returns degraded health and remediation for missing artifacts" do
    RepositoryIntelligence.configure(
      graph: RepositoryIntelligence.graph, contracts: RepositoryIntelligence.contracts,
      playbooks: RepositoryIntelligence.playbooks, provider_status: { available: false },
      artifact_validator: -> { [ "stale generated artifact" ] }
    )

    health = RepositoryIntelligence.health

    assert_equal "unhealthy", health.fetch(:status)
    assert health.fetch(:remediation).any?
  end

  test "exposes health dashboard through MCP" do
    server = RepositoryIntelligence::McpServer.new(
      intelligence: RepositoryIntelligence, playbooks: RepositoryIntelligence.playbooks,
      input: StringIO.new, output: StringIO.new
    )
    response = server.handle(
      "jsonrpc" => "2.0", "id" => 1, "method" => "tools/call",
      "params" => { "name" => "repository_health", "arguments" => {} }
    )

    assert_includes response.dig(:result, :content, 0, :text), '"status": "healthy"'
  end
end

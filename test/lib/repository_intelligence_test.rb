# frozen_string_literal: true

require "test_helper"
require "stringio"
require "tmpdir"
require_relative "../../lib/repository_intelligence"
require_relative "../../lib/repository_intelligence/code_graph_provider"
require_relative "../../lib/repository_intelligence/providers/null_provider"
require_relative "../../lib/repository_intelligence/providers/command_provider"
require_relative "../../lib/repository_intelligence/platform"
require_relative "../../lib/repository_intelligence/graph_exports"
require_relative "../../lib/repository_intelligence/graph_validator"
require_relative "../../lib/repository_intelligence/mcp_server"

class RepositoryIntelligenceTest < ActiveSupport::TestCase
  test "builds a deterministic governance graph and bounded impact result" do
    manifest = {
      files: [
        { path: "app/models/customer.rb", sha256: "a" * 64 },
        { path: "test/models/customer_test.rb", sha256: "b" * 64 },
        { path: "docs/customers.md", sha256: "c" * 64 }
      ]
    }
    provider = RepositoryIntelligence::Providers::NullProvider.new.index(repository_path: Rails.root, repository_commit: "abc")
    graph = RepositoryIntelligence::GovernanceScanner.new(repository_path: Rails.root, manifest:, provider_result: provider).scan

    assert graph.nodes.key?("model:Customer")
    assert graph.nodes.key?("test:Models::Customer")
    assert_operator graph.impact("model:Customer", depth: 2).size, :>=, 1
    assert_empty RepositoryIntelligence::GraphValidator.new(graph).validate
  end

  test "exposes one canonical query API and capability registry" do
    graph = RepositoryIntelligence::GovernanceGraph.new
    graph.add_node(RepositoryIntelligence::Node.new(id: "model:Customer", type: "model", name: "Customer", path: "app/models/customer.rb", properties: {}))
    graph.add_node(RepositoryIntelligence::Node.new(id: "job:CustomerSync", type: "job", name: "CustomerSync", path: "app/jobs/customer_sync_job.rb", properties: {}))
    graph.add_edge(RepositoryIntelligence::Edge.new(from: "job:CustomerSync", to: "model:Customer", type: "USES", properties: {}))
    contracts = [ { "id" => "customer", "version" => 1, "owns" => [ "Customer" ], "invariants" => [ "tenant boundary is required" ] } ]
    playbooks = [ { "id" => "implement-feature", "title" => "Implement feature" } ]

    RepositoryIntelligence.configure(
      graph:, contracts:, playbooks:, manifest: { files: [] }, readiness: { status: "ready" }
    )

    assert_equal "Customer", RepositoryIntelligence.describe_module("Customer").dig(:node, :name)
    assert_equal 1, RepositoryIntelligence.search(type: :job).size
    assert_equal [ "job:CustomerSync", "model:Customer" ], RepositoryIntelligence.dependency_path(from: "CustomerSync", to: "Customer")
    assert_equal "customer", RepositoryIntelligence.contract("Customer").fetch("id")
    assert_equal "implement-feature", RepositoryIntelligence.playbook("implement_feature").fetch("id")
    assert_equal contracts, RepositoryIntelligence.contracts
    assert RepositoryIntelligence.capabilities.key?(:graph)
    assert_equal 2, RepositoryIntelligence.statistics.fetch(:nodes)
  end

  test "publishes lifecycle events through the facade" do
    graph = RepositoryIntelligence::GovernanceGraph.new
    RepositoryIntelligence.configure(graph:, contracts: [], playbooks: [])
    events = []
    RepositoryIntelligence.subscribe(:graph_updated) { |event| events << event.payload }

    RepositoryIntelligence.publish(:graph_updated, repository_commit: "abc")

    assert_equal "abc", events.first.fetch(:repository_commit)
  end

  test "exports portable graph representations" do
    graph = RepositoryIntelligence::GovernanceGraph.new
    graph.add_node(RepositoryIntelligence::Node.new(id: "model:Customer", type: "model", name: "Customer", path: "app/models/customer.rb", properties: {}))
    exports = RepositoryIntelligence::GraphExports.new(graph)

    assert_equal "model:Customer", exports.json_ld.fetch("@graph").first.fetch("@id")
    assert_includes exports.mermaid, "graph TD"
    assert_includes exports.dot, "digraph repository"
  end

  test "detects provider executables without a shell builtin" do
    Dir.mktmpdir do |directory|
      executable = File.join(directory, "provider")
      File.write(executable, "#!/bin/sh\necho provider 1.0\n")
      FileUtils.chmod(0o755, executable)
      provider = RepositoryIntelligence::Providers::CommandProvider.new(
        command: executable, provider_name: "fixture", index_arguments: []
      )

      assert provider.available?
      assert_equal "provider 1.0", provider.status.fetch(:version)
    end
  end

  test "validates contracts and playbooks" do
    Dir.mktmpdir do |directory|
      contracts = File.join(directory, "contracts")
      playbooks = File.join(directory, "playbooks")
      FileUtils.mkdir_p([ contracts, playbooks ])
      File.write(File.join(contracts, "contract.yml"), YAML.dump(
        "id" => "test", "version" => 1, "owns" => [], "may_use" => [], "cannot_use" => [],
        "invariants" => [], "required_tests" => []
      ))
      File.write(File.join(playbooks, "playbook.yml"), YAML.dump(
        "id" => "review", "version" => 1, "title" => "Review", "inputs" => [], "steps" => [], "completion_gate" => []
      ))

      assert_empty RepositoryIntelligence::ContractRegistry.new(contracts).validate
      assert_empty RepositoryIntelligence::PlaybookRegistry.new(playbooks).validate
    end
  end

  test "serves semantic MCP resources tools and audit events" do
    graph = RepositoryIntelligence::GovernanceGraph.new
    graph.add_node(RepositoryIntelligence::Node.new(id: "module:test", type: "module", name: "Test", path: nil, properties: {}))
    RepositoryIntelligence.configure(
      graph:, contracts: [ { "id" => "test", "owns" => [ "Test" ] } ], playbooks: [],
      manifest: { files: [] }, readiness: { status: "ready" }
    )
    server = RepositoryIntelligence::McpServer.new(
      intelligence: RepositoryIntelligence, playbooks: [], provider_status: { available: true },
      input: StringIO.new, output: StringIO.new
    )

    initialized = server.handle("jsonrpc" => "2.0", "id" => 1, "method" => "initialize")
    described = server.handle(
      "jsonrpc" => "2.0", "id" => 2, "method" => "tools/call",
      "params" => { "name" => "describe_module", "arguments" => { "id" => "module:test" } }
    )
    provider = server.handle(
      "jsonrpc" => "2.0", "id" => 3, "method" => "resources/read",
      "params" => { "uri" => "platform://provider" }
    )
    audit = server.handle(
      "jsonrpc" => "2.0", "id" => 4, "method" => "resources/read",
      "params" => { "uri" => "platform://audit" }
    )

    assert_equal "2025-06-18", initialized.dig(:result, :protocolVersion)
    assert_includes described.dig(:result, :content, 0, :text), "module:test"
    assert_includes provider.dig(:result, :contents, 0, :text), "available"
    assert_includes audit.dig(:result, :contents, 0, :text), "describe_module"
  end

  test "denies MCP writes and enforces request budgets" do
    RepositoryIntelligence.configure(graph: RepositoryIntelligence::GovernanceGraph.new, contracts: [], playbooks: [])
    guard = RepositoryIntelligence::McpRequestGuard.new(max_requests: 1)
    server = RepositoryIntelligence::McpServer.new(
      intelligence: RepositoryIntelligence, playbooks: [], guard:, input: StringIO.new, output: StringIO.new
    )

    denied = server.handle(
      "jsonrpc" => "2.0", "id" => 1, "method" => "tools/call",
      "params" => { "name" => "generate_artifacts", "arguments" => {} }
    )
    limited = server.handle("jsonrpc" => "2.0", "id" => 2, "method" => "initialize")

    assert_equal(-32602, denied.dig(:error, :code))
    assert_equal(-32001, limited.dig(:error, :code))
  end

  test "defers provider indexing until nodes or edges are accessed" do
    indexed = false
    mock_provider = Class.new(RepositoryIntelligence::CodeGraphProvider) do
      define_method(:index) do |repository_path:, repository_commit:|
        indexed = true
        RepositoryIntelligence::CodeGraphProvider::Result.new(
          provider: "mock", repository_commit:, nodes: [], edges: [], metadata: {}
        )
      end
    end.new

    lazy = RepositoryIntelligence::LazyProviderResult.new(
      provider: mock_provider, repository_path: "/tmp", repository_commit: "commit123"
    )

    refute lazy.loaded?
    refute indexed
    assert_equal "commit123", lazy.repository_commit

    assert_equal [], lazy.nodes
    assert lazy.loaded?
    assert indexed
  end
end

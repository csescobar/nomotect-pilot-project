# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "json"
require "pathname"
require "stringio"
require "tmpdir"
require_relative "../../lib/repository_intelligence"
require_relative "../../lib/repository_intelligence/platform"
require_relative "../../lib/repository_intelligence/providers/command_provider"
require_relative "../../lib/repository_intelligence/sqlite_graph_store"
require_relative "../../lib/repository_intelligence/mcp_server"
require_relative "../../lib/repository_intelligence/mcp_playbook_tools"
require_relative "../../lib/repository_intelligence/mcp_health_tools"
require_relative "../../lib/repository_intelligence/mcp_request_guard"

class RepositoryIntelligenceCertificationTest < ActiveSupport::TestCase
  def build_graph(customer_name: "Customer")
    graph = RepositoryIntelligence::GovernanceGraph.new
    graph.add_node(RepositoryIntelligence::Node.new(
      id: "model:Customer", type: "model", name: customer_name,
      path: "app/models/customer.rb", properties: {}
    ))
    graph.add_node(RepositoryIntelligence::Node.new(
      id: "document:Customer", type: "document", name: "Customer",
      path: "docs/customer.md", properties: {}
    ))
    graph.add_edge(RepositoryIntelligence::Edge.new(
      from: "model:Customer", to: "document:Customer", type: "DOCUMENTED_BY", properties: {}
    ))
    graph
  end

  def configure_platform(graph: build_graph, provider_status: { available: true, provider: "fixture" })
    contracts = [ {
      "id" => "customer", "version" => 1, "owns" => [ "Customer" ],
      "invariants" => [ "security control", "privacy control", "tenant boundary" ]
    } ]
    playbooks = [ {
      "id" => "repository-readiness", "version" => 1, "title" => "Repository readiness",
      "steps" => [ { "id" => "health", "tool" => "repository.readiness", "args" => {} } ],
      "completion_gate" => [ "repository_ready" ]
    } ]
    RepositoryIntelligence.configure(
      graph:, contracts:, playbooks:, manifest: { files: [] }, readiness: { status: "ready" },
      provider_status:, validator: -> { [] }, artifact_validator: -> { [] }
    )
  end

  test "command providers report unavailable, malformed, and failing executions without corrupting graph state" do
    configure_platform
    original_statistics = RepositoryIntelligence.statistics

    unavailable = RepositoryIntelligence::Providers::CommandProvider.new(
      command: "/missing/provider", provider_name: "fixture", index_arguments: [ "index" ]
    )
    assert_not unavailable.available?
    assert_raises(RuntimeError) { unavailable.index(repository_path: ".", repository_commit: "abc") }

    Dir.mktmpdir do |directory|
      malformed = File.join(directory, "malformed-provider")
      File.write(malformed, "#!/usr/bin/env ruby\nputs 'not-json'\n")
      FileUtils.chmod("u+x", malformed)
      result = RepositoryIntelligence::Providers::CommandProvider.new(
        command: malformed, provider_name: "fixture", index_arguments: []
      ).index(repository_path: ".", repository_commit: "abc")
      assert_empty result.nodes
      assert_empty result.edges

      failing = File.join(directory, "failing-provider")
      File.write(failing, "#!/usr/bin/env ruby\nwarn 'failed fixture'\nexit 2\n")
      FileUtils.chmod("u+x", failing)
      provider = RepositoryIntelligence::Providers::CommandProvider.new(
        command: failing, provider_name: "fixture", index_arguments: []
      )
      assert_raises(RuntimeError) { provider.index(repository_path: ".", repository_commit: "abc") }
    end

    assert_equal original_statistics, RepositoryIntelligence.statistics
  end

  test "incremental SQLite replacement converges with a clean full replacement" do
    skip "sqlite3 is unavailable" unless system("command", "-v", "sqlite3", out: File::NULL, err: File::NULL)

    Dir.mktmpdir do |directory|
      incremental_path = File.join(directory, "incremental.sqlite3")
      clean_path = File.join(directory, "clean.sqlite3")
      original = build_graph
      changed = build_graph(customer_name: "CustomerAccount")

      incremental = RepositoryIntelligence::SqliteGraphStore.new(path: incremental_path)
      incremental.replace(graph: original, repository_commit: "one", provider: "fixture")
      incremental.replace_sources(
        graph: changed, source_paths: [ "app/models/customer.rb" ],
        repository_commit: "two", provider: "fixture"
      )
      clean = RepositoryIntelligence::SqliteGraphStore.new(path: clean_path)
      clean.replace(graph: changed, repository_commit: "two", provider: "fixture")

      assert_equal clean.node("model:Customer"), incremental.node("model:Customer")
      assert_equal clean.impact("model:Customer", depth: 2), incremental.impact("model:Customer", depth: 2)
      assert_equal "two", incremental.metadata.fetch("repository_commit")
    end
  end

  test "health findings explain failure and disappear after recovery" do
    configure_platform(provider_status: { available: false, provider: "fixture" })
    unhealthy = RepositoryIntelligence.health
    assert_includes %w[degraded unhealthy], unhealthy.fetch(:status)
    assert unhealthy.fetch(:remediation).any?

    configure_platform
    healthy = RepositoryIntelligence.health
    assert_equal "healthy", healthy.fetch(:status)
    assert_empty healthy.fetch(:remediation)
  end

  test "MCP rejects traversal, disabled writes, and exhausted request budgets" do
    configure_platform
    Dir.mktmpdir do |directory|
      File.write(File.join(directory, "safe.json"), "{}")
      server = RepositoryIntelligence::McpServer.new(
        intelligence: RepositoryIntelligence, playbooks: RepositoryIntelligence.playbooks,
        artifact_directory: directory, guard: RepositoryIntelligence::McpRequestGuard.new(max_requests: 2),
        input: StringIO.new, output: StringIO.new
      )

      safe = server.handle(
        "jsonrpc" => "2.0", "id" => 1, "method" => "resources/read",
        "params" => { "uri" => "platform://artifacts/safe.json" }
      )
      assert safe[:result]

      traversal = server.handle(
        "jsonrpc" => "2.0", "id" => 2, "method" => "resources/read",
        "params" => { "uri" => "platform://artifacts/../outside" }
      )
      assert traversal[:error]

      limited = server.handle(
        "jsonrpc" => "2.0", "id" => 3, "method" => "tools/call",
        "params" => { "name" => "repository_health", "arguments" => {} }
      )
      assert_equal(-32_001, limited.dig(:error, :code))
    end

    write_server = RepositoryIntelligence::McpServer.new(
      intelligence: RepositoryIntelligence, playbooks: RepositoryIntelligence.playbooks,
      input: StringIO.new, output: StringIO.new
    )
    denied = write_server.handle(
      "jsonrpc" => "2.0", "id" => 4, "method" => "tools/call",
      "params" => { "name" => "generate_artifacts", "arguments" => {} }
    )
    assert_includes denied.dig(:error, :message), "writes are disabled"
  end
end

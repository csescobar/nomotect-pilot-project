# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require_relative "../../lib/repository_intelligence/platform"
require_relative "../../lib/repository_intelligence/sqlite_graph_store"
require_relative "../../lib/repository_intelligence/snapshot_drift"

class RepositoryIntelligenceStorageTest < ActiveSupport::TestCase
  test "persists graph metadata and supports recursive impact" do
    skip "sqlite3 command is unavailable" unless system("command", "-v", "sqlite3", out: File::NULL, err: File::NULL)

    Dir.mktmpdir do |directory|
      graph = RepositoryIntelligence::GovernanceGraph.new
      graph.add_node(RepositoryIntelligence::Node.new(id: "model:Customer", type: "model", name: "Customer", path: "app/models/customer.rb", properties: {}))
      graph.add_node(RepositoryIntelligence::Node.new(id: "test:Customer", type: "test", name: "CustomerTest", path: "test/models/customer_test.rb", properties: {}))
      graph.add_edge(RepositoryIntelligence::Edge.new(from: "model:Customer", to: "test:Customer", type: "TESTED_BY", properties: {}))
      store = RepositoryIntelligence::SqliteGraphStore.new(path: File.join(directory, "graph.sqlite3"))

      store.replace(graph:, repository_commit: "abc123", provider: "null")

      assert_equal "abc123", store.metadata.fetch("repository_commit")
      assert_equal "Customer", store.node("model:Customer").fetch("name")
      assert_equal 2, store.impact("model:Customer", depth: 1).size
    end
  end

  test "detects committed graph snapshot drift" do
    Dir.mktmpdir do |directory|
      payload = { schema_version: "1.0", nodes: [], edges: [] }
      snapshot = File.join(directory, "graph.json")
      json = JSON.pretty_generate(payload) << "\n"
      File.write(snapshot, json)
      File.write("#{snapshot}.sha256", "#{Digest::SHA256.hexdigest(json)}  graph.json\n")

      fresh = RepositoryIntelligence::SnapshotDrift.new(snapshot_path: snapshot).validate(payload)
      stale = RepositoryIntelligence::SnapshotDrift.new(snapshot_path: snapshot).validate(payload.merge(nodes: [ { id: "changed" } ]))

      assert fresh.fresh
      assert_not stale.fresh
      assert_includes stale.findings, "generated snapshot differs from committed checksum"
    end
  end
end

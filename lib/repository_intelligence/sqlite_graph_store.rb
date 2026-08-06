# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "open3"
require "time"

module RepositoryIntelligence
  class SqliteGraphStore
    SCHEMA_VERSION = "1.0"

    def initialize(path:, command: ENV.fetch("SQLITE3_COMMAND", "sqlite3"), runner: nil)
      @path = File.expand_path(path)
      @command = command
      @runner = runner || method(:run_command)
    end

    attr_reader :path

    def available?
      system("command", "-v", command, out: File::NULL, err: File::NULL)
    end

    def replace(graph:, repository_commit:, provider:)
      execute(transaction_sql(graph:, repository_commit:, provider:, source_paths: nil))
      self
    end

    def replace_sources(graph:, source_paths:, repository_commit:, provider:)
      normalized = Array(source_paths).map(&:to_s).uniq.sort
      execute(transaction_sql(graph:, repository_commit:, provider:, source_paths: normalized))
      self
    end

    def metadata
      query_json("SELECT key, value FROM graph_metadata ORDER BY key;").to_h do |row|
        [ row.fetch("key"), row.fetch("value") ]
      end
    end

    def node(id)
      query_json("SELECT id, type, name, path, properties FROM nodes WHERE id = #{quote(id)} LIMIT 1;").first
    end

    def impact(id, depth: 2)
      depth = [ [ depth.to_i, 1 ].max, 10 ].min
      query_json(<<~SQL)
        WITH RECURSIVE traversal(id, depth) AS (
          SELECT #{quote(id)}, 0
          UNION
          SELECT CASE WHEN edges.from_node_id = traversal.id THEN edges.to_node_id ELSE edges.from_node_id END,
                 traversal.depth + 1
          FROM edges
          JOIN traversal ON edges.from_node_id = traversal.id OR edges.to_node_id = traversal.id
          WHERE traversal.depth < #{depth}
        )
        SELECT DISTINCT nodes.id, nodes.type, nodes.name, nodes.path, nodes.properties
        FROM nodes JOIN traversal ON nodes.id = traversal.id ORDER BY nodes.id;
      SQL
    end

    private

    attr_reader :command, :runner

    def transaction_sql(graph:, repository_commit:, provider:, source_paths:)
      node_rows = graph.nodes.values.select { |node| source_paths.nil? || source_paths.include?(node.path) }
      selected_ids = node_rows.map(&:id)
      edge_rows = graph.edges.select do |edge|
        source_paths.nil? || selected_ids.include?(edge.from) || selected_ids.include?(edge.to)
      end

      statements = [ schema_sql, "BEGIN IMMEDIATE;" ]
      if source_paths
        source_paths.each { |source| statements << "DELETE FROM nodes WHERE path = #{quote(source)};" }
        selected_ids.each do |id|
          statements << "DELETE FROM edges WHERE from_node_id = #{quote(id)} OR to_node_id = #{quote(id)};"
        end
      else
        statements.concat([ "DELETE FROM edges;", "DELETE FROM nodes;" ])
      end
      node_rows.each { |node| statements << insert_node_sql(node) }
      edge_rows.each { |edge| statements << insert_edge_sql(edge) }
      statements << metadata_sql("schema_version", SCHEMA_VERSION)
      statements << metadata_sql("repository_commit", repository_commit)
      statements << metadata_sql("provider", provider)
      statements << metadata_sql("updated_at", Time.now.utc.iso8601)
      statements << "COMMIT;"
      statements.join("\n")
    end

    def schema_sql
      <<~SQL
        PRAGMA foreign_keys = ON;
        PRAGMA journal_mode = WAL;
        CREATE TABLE IF NOT EXISTS graph_metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS nodes (
          id TEXT PRIMARY KEY, type TEXT NOT NULL, name TEXT NOT NULL, path TEXT,
          properties TEXT NOT NULL, content_hash TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS edges (
          id TEXT PRIMARY KEY, from_node_id TEXT NOT NULL, to_node_id TEXT NOT NULL,
          type TEXT NOT NULL, properties TEXT NOT NULL, content_hash TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS index_nodes_on_type ON nodes(type);
        CREATE INDEX IF NOT EXISTS index_nodes_on_path ON nodes(path);
        CREATE INDEX IF NOT EXISTS index_edges_on_from ON edges(from_node_id);
        CREATE INDEX IF NOT EXISTS index_edges_on_to ON edges(to_node_id);
      SQL
    end

    def insert_node_sql(node)
      hash = Digest::SHA256.hexdigest(JSON.generate(node.to_h))
      "INSERT OR REPLACE INTO nodes VALUES (#{quote(node.id)}, #{quote(node.type)}, #{quote(node.name)}, #{quote(node.path)}, #{quote(JSON.generate(node.properties))}, #{quote(hash)});"
    end

    def insert_edge_sql(edge)
      id = Digest::SHA256.hexdigest([ edge.from, edge.type, edge.to ].join("\0"))
      hash = Digest::SHA256.hexdigest(JSON.generate(edge.to_h))
      "INSERT OR REPLACE INTO edges VALUES (#{quote(id)}, #{quote(edge.from)}, #{quote(edge.to)}, #{quote(edge.type)}, #{quote(JSON.generate(edge.properties))}, #{quote(hash)});"
    end

    def metadata_sql(key, value)
      "INSERT OR REPLACE INTO graph_metadata(key, value) VALUES (#{quote(key)}, #{quote(value)});"
    end

    def execute(sql)
      FileUtils.mkdir_p(File.dirname(path))
      output, error, status = runner.call(command, path, stdin_data: sql)
      raise "SQLite graph update failed: #{error}\n#{output}" unless status.success?

      output
    end

    def query_json(sql)
      FileUtils.mkdir_p(File.dirname(path))
      output, error, status = runner.call(command, "-json", path, sql)
      raise "SQLite graph query failed: #{error}" unless status.success?

      output.strip.empty? ? [] : JSON.parse(output)
    end

    def quote(value)
      return "NULL" if value.nil?

      "'#{value.to_s.gsub("'", "''")}'"
    end

    def run_command(*arguments, **options)
      Open3.capture3(*arguments, **options)
    end
  end
end

# frozen_string_literal: true

require "digest"
require "json"
require "pathname"
require "yaml"

module RepositoryIntelligence
  Platform = self
  Node = Data.define(:id, :type, :name, :path, :properties)
  Edge = Data.define(:from, :to, :type, :properties)

  class GovernanceGraph
    def initialize(lazy_provider: nil)
      @nodes = {}
      @edges = []
      @lazy_provider = lazy_provider
      @provider_loaded = false
    end

    def add_node(node)
      @nodes[node.id] = node
    end

    def add_edge(edge)
      @edges << edge unless @edges.any? { |candidate| candidate == edge }
    end

    def nodes
      ensure_provider_loaded!
      @nodes
    end

    def edges
      ensure_provider_loaded!
      @edges
    end

    def impact(node_id, depth: 2)
      ensure_provider_loaded!
      visited = { node_id => 0 }
      queue = [ node_id ]
      until queue.empty?
        current = queue.shift
        next if visited.fetch(current) >= depth

        @edges.select { |edge| edge.from == current || edge.to == current }.each do |edge|
          other = edge.from == current ? edge.to : edge.from
          next if visited.key?(other)

          visited[other] = visited.fetch(current) + 1
          queue << other
        end
      end
      visited.keys.filter_map { |id| @nodes[id] }
    end

    def to_h
      ensure_provider_loaded!
      {
        schema_version: "1.0",
        nodes: @nodes.values.sort_by(&:id).map(&:to_h),
        edges: @edges.sort_by { |edge| [ edge.from, edge.type, edge.to ] }.map(&:to_h)
      }
    end

    private

    def ensure_provider_loaded!
      return if @provider_loaded || @lazy_provider.nil?

      @provider_loaded = true
      Array(@lazy_provider.nodes).each do |node|
        add_node(node.is_a?(Node) ? node : Node.new(**symbolize(node)))
      end
      Array(@lazy_provider.edges).each do |edge|
        add_edge(edge.is_a?(Edge) ? edge : Edge.new(**symbolize(edge)))
      end
    end

    def symbolize(hash)
      hash.is_a?(Hash) ? hash.transform_keys(&:to_sym) : hash
    end
  end

  class GovernanceScanner
    SOURCE_PATTERNS = {
      model: %r{\Aapp/models/(.+)\.rb\z}, controller: %r{\Aapp/controllers/(.+)_controller\.rb\z},
      job: %r{\Aapp/jobs/(.+)_job\.rb\z}, policy: %r{\Aapp/policies/(.+)_policy\.rb\z},
      component: %r{\Aapp/components/(.+)_component\.rb\z}, test: %r{\Atest/(.+)_test\.rb\z},
      document: %r{\Adocs/(.+)\.md\z}
    }.freeze

    def initialize(repository_path:, manifest:, provider_result:)
      @repository_path = Pathname(repository_path)
      @manifest = manifest
      @provider_result = provider_result
    end

    def scan
      graph = GovernanceGraph.new(lazy_provider: provider_result)

      manifest.fetch(:files).each do |file|
        path = file.fetch(:path)
        type, match = SOURCE_PATTERNS.filter_map { |kind, pattern| [ kind, pattern.match(path) ] if pattern.match?(path) }.first
        next unless type

        name = match[1].split("/").map { |part| part.split("_").map(&:capitalize).join }.join("::")
        id = "#{type}:#{name}"
        graph.add_node(Node.new(id:, type: type.to_s, name:, path:, properties: { sha256: file.fetch(:sha256), source: "platform" }))
        link_tests(graph, id, name) if type == :test
        link_docs(graph, id, path) if type == :document
      end
      graph
    end

    private

    attr_reader :repository_path, :manifest, :provider_result

    def link_tests(graph, test_id, name)
      target = name.sub(/Test\z/, "")
      graph.nodes.each_value do |node|
        next if node.id == test_id
        graph.add_edge(Edge.new(from: node.id, to: test_id, type: "TESTED_BY", properties: {})) if target.include?(node.name.split("::").last)
      end
    end

    def link_docs(graph, document_id, path)
      graph.nodes.each_value do |node|
        next if node.id == document_id
        next unless path.downcase.include?(node.name.split("::").last.downcase)
        graph.add_edge(Edge.new(from: node.id, to: document_id, type: "DOCUMENTED_BY", properties: {}))
      end
    end

    def symbolize(value)
      value.transform_keys(&:to_sym)
    end
  end

  class ContractRegistry
    REQUIRED_KEYS = %w[id version owns may_use cannot_use invariants required_tests].freeze

    def initialize(path)
      @path = Pathname(path)
    end

    def load
      return [] unless path.directory?
      path.glob("*.yml").sort.map { |file| YAML.safe_load_file(file, aliases: false) }
    end

    def validate
      load.flat_map do |contract|
        missing = REQUIRED_KEYS - contract.keys
        missing.map { |key| "#{contract['id'] || 'unknown'} missing #{key}" }
      end
    end

    private

    attr_reader :path
  end

  class PlaybookRegistry
    REQUIRED_KEYS = %w[id version title inputs steps completion_gate].freeze

    def initialize(path)
      @path = Pathname(path)
    end

    def load
      return [] unless path.directory?
      path.glob("*.yml").sort.map { |file| YAML.safe_load_file(file, aliases: false) }
    end

    def fetch(id)
      load.find { |playbook| playbook.fetch("id") == id } || raise(KeyError, "Unknown playbook: #{id}")
    end

    def validate
      load.flat_map do |playbook|
        (REQUIRED_KEYS - playbook.keys).map { |key| "#{playbook['id'] || 'unknown'} missing #{key}" }
      end
    end

    private

    attr_reader :path
  end

  class SnapshotWriter
    def initialize(output_directory:)
      @output_directory = Pathname(output_directory)
    end

    def write(name, payload)
      output_directory.mkpath
      json = JSON.pretty_generate(payload) << "\n"
      file = output_directory.join("#{name}.json")
      file.write(json)
      output_directory.join("#{name}.json.sha256").write("#{Digest::SHA256.hexdigest(json)}  #{file.basename}\n")
      file
    end

    private

    attr_reader :output_directory
  end

  class ReadinessReport
    def initialize(manifest:, graph:, contract_errors:, playbook_errors:, indexed_commit:, current_commit:)
      @manifest = manifest
      @graph = graph
      @contract_errors = contract_errors
      @playbook_errors = playbook_errors
      @indexed_commit = indexed_commit
      @current_commit = current_commit
    end

    def to_h
      findings = []
      findings << "graph is stale" unless indexed_commit == current_commit
      findings.concat(contract_errors)
      findings.concat(playbook_errors)
      findings << "manifest contains no files" if manifest.fetch(:files).empty?
      {
        schema_version: "1.0",
        status: findings.empty? ? "ready" : "not_ready",
        indexed_commit:, current_commit:,
        counts: { files: manifest.fetch(:files).size, nodes: graph.nodes.size, edges: graph.edges.size },
        findings:
      }
    end

    private

    attr_reader :manifest, :graph, :contract_errors, :playbook_errors, :indexed_commit, :current_commit
  end
end

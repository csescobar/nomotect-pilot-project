# frozen_string_literal: true

module RepositoryIntelligence
  class QueryEngine
    def initialize(graph:, contracts:, playbooks:)
      @graph = graph
      @contracts = contracts
      @playbooks = playbooks
    end

    def describe(identifier)
      node = resolve_node(identifier)
      {
        node: node.to_h,
        relationships: graph.edges.select { |edge| edge.from == node.id || edge.to == node.id }.map(&:to_h),
        impact: impact_analysis(node.id, depth: 1)
      }
    end

    def search(query: nil, type: nil, limit: 50)
      normalized = query.to_s.downcase
      graph.nodes.values.select do |node|
        (type.nil? || node.type == type.to_s) &&
          (normalized.empty? || [ node.id, node.name, node.path ].compact.any? { |value| value.downcase.include?(normalized) })
      end.sort_by(&:id).first([ [ limit.to_i, 1 ].max, 200 ].min).map(&:to_h)
    end

    def impact_analysis(identifier, depth: 2)
      node = resolve_node(identifier)
      graph.impact(node.id, depth: bounded_depth(depth)).map(&:to_h)
    end

    def dependency_path(from:, to:, max_depth: 6)
      start = resolve_node(from).id
      target = resolve_node(to).id
      queue = [ [ start ] ]
      visited = { start => true }

      until queue.empty?
        path = queue.shift
        return path if path.last == target
        next if path.size > bounded_depth(max_depth) + 1

        neighbors(path.last).each do |neighbor|
          next if visited[neighbor]

          visited[neighbor] = true
          queue << path + [ neighbor ]
        end
      end
      []
    end

    def contract(identifier)
      normalized = identifier.to_s.downcase
      contracts.find do |item|
        item.fetch("id", "").downcase == normalized || Array(item["owns"]).any? { |owned| owned.to_s.downcase == normalized }
      end
    end

    def playbook(identifier)
      normalized = identifier.to_s.downcase.tr("_", "-")
      playbooks.find { |item| item.fetch("id", "").downcase.tr("_", "-") == normalized }
    end

    def invariants(kind: nil)
      contracts.flat_map do |contract|
        Array(contract["invariants"]).filter_map do |invariant|
          text = invariant.to_s
          next if kind && !text.downcase.include?(kind.to_s.downcase)

          { contract: contract.fetch("id"), invariant: text }
        end
      end
    end

    def statistics
      {
        nodes: graph.nodes.size,
        edges: graph.edges.size,
        node_types: graph.nodes.values.group_by(&:type).transform_values(&:size).sort.to_h,
        edge_types: graph.edges.group_by(&:type).transform_values(&:size).sort.to_h,
        contracts: contracts.size,
        playbooks: playbooks.size
      }
    end

    private

    attr_reader :graph, :contracts, :playbooks

    def resolve_node(identifier)
      value = identifier.to_s
      graph.nodes[value] || graph.nodes.values.find { |node| node.name.casecmp?(value) } || raise(KeyError, "Unknown node: #{identifier}")
    end

    def neighbors(identifier)
      graph.edges.filter_map do |edge|
        edge.to if edge.from == identifier
      end.uniq.sort
    end

    def bounded_depth(depth)
      [ [ depth.to_i, 1 ].max, 10 ].min
    end
  end
end

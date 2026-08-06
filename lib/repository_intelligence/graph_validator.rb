# frozen_string_literal: true

require "set"

module RepositoryIntelligence
  class GraphValidator
    def initialize(graph)
      @graph = graph
    end

    def validate
      errors = []
      graph.edges.each do |edge|
        errors << "missing source node: #{edge.from}" unless graph.nodes.key?(edge.from)
        errors << "missing target node: #{edge.to}" unless graph.nodes.key?(edge.to)
        errors << "invalid self edge: #{edge.from}" if edge.from == edge.to
      end
      errors.concat(duplicate_edges)
      errors
    end

    def diff(other)
      current_nodes = graph.nodes.keys.to_set
      other_nodes = other.nodes.keys.to_set
      current_edges = graph.edges.map { |edge| [ edge.from, edge.type, edge.to ] }.to_set
      other_edges = other.edges.map { |edge| [ edge.from, edge.type, edge.to ] }.to_set
      {
        added_nodes: (current_nodes - other_nodes).sort,
        removed_nodes: (other_nodes - current_nodes).sort,
        added_edges: (current_edges - other_edges).to_a.sort,
        removed_edges: (other_edges - current_edges).to_a.sort
      }
    end

    private

    attr_reader :graph

    def duplicate_edges
      grouped = graph.edges.group_by { |edge| [ edge.from, edge.type, edge.to ] }
      grouped.filter_map { |key, values| "duplicate edge: #{key.join(' -> ')}" if values.size > 1 }
    end
  end
end

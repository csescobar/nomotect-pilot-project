# frozen_string_literal: true

require "json"

module RepositoryIntelligence
  class GraphExports
    def initialize(graph)
      @graph = graph
    end

    def json_ld
      {
        "@context" => {
          "type" => "@type",
          "name" => "https://schema.org/name",
          "from" => { "@id" => "https://schema.org/source", "@type" => "@id" },
          "to" => { "@id" => "https://schema.org/target", "@type" => "@id" }
        },
        "@graph" => graph.nodes.values.map { |node| node.to_h.merge("@id" => node.id) } +
          graph.edges.each_with_index.map { |edge, index| edge.to_h.merge("@id" => "edge:#{index}") }
      }
    end

    def mermaid
      lines = [ "graph TD" ]
      graph.nodes.values.sort_by(&:id).each do |node|
        lines << %(  #{identifier(node.id)}["#{escape(node.name)}"])
      end
      graph.edges.sort_by { |edge| [ edge.from, edge.type, edge.to ] }.each do |edge|
        lines << %(  #{identifier(edge.from)} -->|#{escape(edge.type)}| #{identifier(edge.to)})
      end
      lines.join("\n") << "\n"
    end

    def dot
      lines = [ "digraph repository {" ]
      graph.nodes.values.sort_by(&:id).each do |node|
        lines << %(  "#{escape(node.id)}" [label="#{escape(node.name)}"];)
      end
      graph.edges.sort_by { |edge| [ edge.from, edge.type, edge.to ] }.each do |edge|
        lines << %(  "#{escape(edge.from)}" -> "#{escape(edge.to)}" [label="#{escape(edge.type)}"];)
      end
      lines << "}"
      lines.join("\n") << "\n"
    end

    private

    attr_reader :graph

    def identifier(value)
      "n_#{value.gsub(/[^a-zA-Z0-9]/, "_")}"
    end

    def escape(value)
      value.to_s.gsub('"', '\\"')
    end
  end
end

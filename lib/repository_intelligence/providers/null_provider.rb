# frozen_string_literal: true

require_relative "../code_graph_provider"

module RepositoryIntelligence
  module Providers
    class NullProvider < CodeGraphProvider
      def index(repository_path:, repository_commit:)
        Result.new(
          provider: "null",
          repository_commit: repository_commit,
          nodes: [],
          edges: [],
          metadata: { repository_path: File.expand_path(repository_path), structural_index: false }
        )
      end

      def available?
        true
      end
    end
  end
end

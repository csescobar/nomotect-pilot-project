# frozen_string_literal: true

module RepositoryIntelligence
  class CodeGraphProvider
    Result = Data.define(:provider, :repository_commit, :nodes, :edges, :metadata)

    def index(repository_path:, repository_commit:)
      raise NotImplementedError, "#{self.class} must implement #index"
    end

    def available?
      false
    end

    def status
      { available: available?, provider: self.class.name }
    end
  end

  class LazyProviderResult
    attr_reader :repository_commit

    def initialize(provider:, repository_path:, repository_commit:)
      @provider = provider
      @repository_path = repository_path
      @repository_commit = repository_commit
      @result = nil
    end

    def provider
      @provider.status[:provider] || @provider.class.name
    end

    def nodes
      result.nodes
    end

    def edges
      result.edges
    end

    def metadata
      result.metadata
    end

    def loaded?
      !@result.nil?
    end

    private

    def result
      @result ||= begin
        @provider.index(repository_path: @repository_path, repository_commit: @repository_commit)
      rescue StandardError => error
        CodeGraphProvider::Result.new(
          provider: provider,
          repository_commit: @repository_commit,
          nodes: [],
          edges: [],
          metadata: { error: error.message }
        )
      end
    end
  end
end

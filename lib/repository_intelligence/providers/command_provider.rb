# frozen_string_literal: true

require "json"
require "open3"
require "pathname"
require_relative "../code_graph_provider"

module RepositoryIntelligence
  module Providers
    class CommandProvider < CodeGraphProvider
      def initialize(command:, provider_name:, version_arguments: [ "--version" ], index_arguments:)
        @command = command
        @provider_name = provider_name
        @version_arguments = version_arguments
        @index_arguments = index_arguments
      end

      def available?
        executable = Pathname(command)
        return executable.file? && executable.executable? if executable.absolute? || command.include?(File::SEPARATOR)

        ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |directory|
          candidate = File.join(directory, command)
          File.file?(candidate) && File.executable?(candidate)
        end
      end

      def status
        return super unless available?

        output, status = Open3.capture2e(command, *version_arguments, stdin_data: "")
        { available: status.success?, provider: provider_name, version: output.strip }
      end

      def index(repository_path:, repository_commit:)
        raise "#{provider_name} is unavailable" unless available?

        output, status = Open3.capture2e(command, *index_arguments, repository_path.to_s, stdin_data: "")
        raise "#{provider_name} indexing failed: #{output}" unless status.success?

        payload = parse_output(output)
        Result.new(
          provider: provider_name,
          repository_commit:,
          nodes: payload.fetch("nodes", []),
          edges: payload.fetch("edges", []),
          metadata: { version: self.status[:version], structural_index: true }
        )
      end

      private

      attr_reader :command, :provider_name, :version_arguments, :index_arguments

      def parse_output(output)
        JSON.parse(output)
      rescue JSON::ParserError
        { "nodes" => [], "edges" => [], "raw_output" => output.lines.last(20).join }
      end
    end

    class CodebaseMemoryProvider < CommandProvider
      def initialize(command: ENV.fetch("CODEBASE_MEMORY_COMMAND", "codebase-memory-mcp"))
        super(command:, provider_name: "codebase_memory", index_arguments: [ "cli", "index_repository" ])
      end
    end

    class GitNexusProvider < CommandProvider
      def initialize(command: ENV.fetch("GITNEXUS_COMMAND", "gitnexus"))
        super(command:, provider_name: "gitnexus", index_arguments: [ "analyze", "--json" ])
      end
    end
  end
end

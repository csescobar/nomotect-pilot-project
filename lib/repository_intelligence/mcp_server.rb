# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"
require_relative "mcp_audit_log"
require_relative "mcp_request_guard"

module RepositoryIntelligence
  class McpServer
    PROTOCOL_VERSION = "2025-06-18"

    def initialize(
      intelligence: RepositoryIntelligence, playbooks:, provider_status: {}, artifact_directory: nil,
      allow_writes: false, guard: McpRequestGuard.new, audit_log: McpAuditLog.new,
      input: $stdin, output: $stdout
    )
      @intelligence = intelligence
      @playbooks = playbooks
      @provider_status = provider_status
      @artifact_directory = artifact_directory && Pathname(artifact_directory).expand_path
      @allow_writes = allow_writes
      @guard = guard
      @audit_log = audit_log
      @input = input
      @output = output
    end

    def run
      input.each_line do |line|
        request = JSON.parse(line)
        response = handle(request)
        next if response.nil?

        output.puts(JSON.generate(response))
        output.flush
      rescue JSON::ParserError => error
        output.puts(JSON.generate(error_response(nil, -32700, error.message)))
      end
    end

    def handle(request)
      operation = operation_name(request)
      return nil unless request.key?("id")

      result, duration_ms = guard.call { dispatch(request) }
      audit(request, operation:, status: "success", duration_ms:)
      { jsonrpc: "2.0", id: request["id"], result: }
    rescue KeyError, ArgumentError => error
      audit(request, operation:, status: "invalid_request", duration_ms: 0, error: error.message)
      error_response(request["id"], -32602, error.message)
    rescue McpRequestGuard::LimitExceeded => error
      audit(request, operation:, status: "limited", duration_ms: 0, error: error.message)
      error_response(request["id"], -32001, error.message)
    rescue StandardError => error
      audit(request, operation:, status: "error", duration_ms: 0, error: error.message)
      error_response(request["id"], -32603, error.message)
    end

    private

    attr_reader :intelligence, :playbooks, :provider_status, :artifact_directory, :allow_writes,
                :guard, :audit_log, :input, :output

    def dispatch(request)
      case request.fetch("method")
      when "initialize" then initialize_result
      when "notifications/initialized", "initialized" then {}
      when "ping" then {}
      when "resources/list" then { resources: resources }
      when "resources/read" then read_resource(request.dig("params", "uri"))
      when "resources/templates/list" then { resourceTemplates: [] }
      when "tools/list" then { tools: tools }
      when "tools/call" then call_tool(request.fetch("params"))
      when "prompts/list" then { prompts: prompt_list }
      when "prompts/get" then prompt(request.dig("params", "name"))
      when "completion/complete" then { completion: { values: [] } }
      else raise ArgumentError, "Method not found: #{request['method']}"
      end
    end

    def initialize_result
      {
        protocolVersion: PROTOCOL_VERSION,
        serverInfo: { name: "nomotect-platform", version: "1.1" },
        capabilities: { resources: {}, tools: {}, prompts: {} },
        instructions: "Read-only by default. Generated-file writes require explicit server capability."
      }
    end

    def resources
      base = %w[
        platform://manifest platform://graph platform://capabilities platform://statistics
        platform://contracts platform://playbooks platform://provider platform://readiness platform://audit
      ]
      base.concat(artifact_resources)
      base.map { |uri| { uri:, name: uri.delete_prefix("platform://") } }
    end

    def read_resource(uri)
      payload =
        case uri
        when "platform://manifest" then intelligence.manifest
        when "platform://graph" then intelligence.graph.to_h
        when "platform://capabilities" then intelligence.capabilities
        when "platform://statistics" then intelligence.statistics
        when "platform://contracts" then intelligence.contracts
        when "platform://playbooks" then intelligence.playbooks
        when "platform://provider" then provider_status
        when "platform://readiness" then intelligence.readiness
        when "platform://audit" then audit_log.to_a
        else read_artifact(uri)
        end
      { contents: [ { uri:, mimeType: mime_type(payload), text: serialize(payload) } ] }
    end

    def tools
      [
        tool("describe_module", "Describe a module or repository node", object_schema("id")),
        tool("describe_contract", "Find a machine-readable contract", object_schema("id")),
        tool("describe_playbook", "Find a registered engineering playbook", object_schema("id")),
        tool("search", "Search normalized repository knowledge", search_schema),
        tool("impact_analysis", "Traverse bounded cross-layer impact", object_schema("id", depth: depth_schema(5))),
        tool("dependency_path", "Find a directed dependency path", dependency_schema),
        tool("find_tests", "Find test nodes related to a query", query_schema),
        tool("find_documentation", "Find documentation nodes related to a query", query_schema),
        tool("find_invariants", "Find security, privacy, or tenancy invariants", optional_kind_schema),
        tool("graph_statistics", "Return normalized graph statistics", empty_schema),
        tool("provider_health", "Return provider health and version diagnostics", empty_schema),
        tool("validate_repository", "Run shared repository validation", empty_schema),
        tool("generate_artifacts", "Regenerate deterministic AI artifacts", empty_schema),
        tool("readiness_report", "Return repository readiness", empty_schema)
      ]
    end

    def call_tool(params)
      name = params.fetch("name")
      arguments = params.fetch("arguments", {})
      payload =
        case name
        when "describe_module" then intelligence.describe_module(arguments.fetch("id"))
        when "describe_contract" then intelligence.contract(arguments.fetch("id"))
        when "describe_playbook" then intelligence.playbook(arguments.fetch("id"))
        when "search" then intelligence.search(query: arguments["query"], type: arguments["type"], limit: arguments.fetch("limit", 50))
        when "impact_analysis" then intelligence.impact_analysis(arguments.fetch("id"), depth: arguments.fetch("depth", 2))
        when "dependency_path" then intelligence.dependency_path(from: arguments.fetch("from"), to: arguments.fetch("to"), max_depth: arguments.fetch("max_depth", 6))
        when "find_tests" then intelligence.search(query: arguments["query"], type: "test", limit: arguments.fetch("limit", 50))
        when "find_documentation" then intelligence.search(query: arguments["query"], type: "document", limit: arguments.fetch("limit", 50))
        when "find_invariants" then intelligence.invariants(kind: arguments["kind"])
        when "graph_statistics" then intelligence.statistics
        when "provider_health" then provider_status
        when "validate_repository" then intelligence.validate!
        when "generate_artifacts" then generate_artifacts
        when "readiness_report" then intelligence.readiness
        else raise ArgumentError, "Unknown tool"
        end
      intelligence.publish(:mcp_tool_called, tool: name, read_only: name != "generate_artifacts")
      { content: [ { type: "text", text: JSON.pretty_generate(payload) } ] }
    end

    def generate_artifacts
      raise ArgumentError, "generated-file writes are disabled" unless allow_writes

      result = intelligence.generate!
      { files: result.files.keys, quality: result.quality }
    end

    def prompt_list
      playbooks.map { |item| { name: item.fetch("id"), description: item.fetch("title") } }
    end

    def prompt(name)
      {
        description: "Executable repository playbook",
        messages: [ { role: "user", content: { type: "text", text: YAML.dump(intelligence.playbook(name)) } } ]
      }
    end

    def artifact_resources
      return [] unless artifact_directory&.directory?

      artifact_directory.glob("**/*").select(&:file?).map do |path|
        "platform://artifacts/#{path.relative_path_from(artifact_directory)}"
      end.sort
    end

    def read_artifact(uri)
      prefix = "platform://artifacts/"
      raise ArgumentError, "Unknown resource" unless uri.to_s.start_with?(prefix) && artifact_directory

      relative = Pathname(uri.delete_prefix(prefix))
      path = artifact_directory.join(relative).cleanpath
      root = artifact_directory.realpath
      raise ArgumentError, "Artifact path escapes repository intelligence output" unless path.to_s.start_with?("#{root}/")
      raise ArgumentError, "Unknown resource" unless path.file?

      path.read
    end

    def audit(request, operation:, status:, duration_ms:, error: nil)
      audit_log.record(
        request_id: request && request["id"], method: request && request["method"], operation:,
        status:, duration_ms:, error:
      )
      intelligence.publish(:mcp_request_completed, operation:, status:, duration_ms:)
    rescue StandardError
      nil
    end

    def operation_name(request)
      return "unknown" unless request

      request.dig("params", "name") || request["method"] || "unknown"
    end

    def tool(name, description, input_schema)
      { name:, description:, inputSchema: input_schema }
    end

    def object_schema(required, **properties)
      {
        type: "object", properties: { required => { type: "string" } }.merge(properties),
        required: [ required ], additionalProperties: false
      }
    end

    def query_schema
      {
        type: "object", properties: { query: { type: "string" }, limit: { type: "integer", minimum: 1, maximum: 200 } },
        additionalProperties: false
      }
    end

    def search_schema
      query_schema.merge(properties: query_schema.fetch(:properties).merge(type: { type: "string" }))
    end

    def optional_kind_schema
      { type: "object", properties: { kind: { type: "string" } }, additionalProperties: false }
    end

    def dependency_schema
      {
        type: "object",
        properties: { from: { type: "string" }, to: { type: "string" }, max_depth: depth_schema(10) },
        required: %w[from to], additionalProperties: false
      }
    end

    def depth_schema(maximum)
      { type: "integer", minimum: 1, maximum: }
    end

    def empty_schema
      { type: "object", additionalProperties: false }
    end

    def serialize(payload)
      payload.is_a?(String) ? payload : JSON.pretty_generate(payload)
    end

    def mime_type(payload)
      payload.is_a?(String) ? "text/plain" : "application/json"
    end

    def error_response(id, code, message)
      { jsonrpc: "2.0", id:, error: { code:, message:, data: { request_count: guard.request_count } } }
    end
  end
end

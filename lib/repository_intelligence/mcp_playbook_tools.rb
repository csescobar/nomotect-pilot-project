# frozen_string_literal: true

module RepositoryIntelligence
  module McpPlaybookTools
    def tools
      super + [
        tool("validate_playbook", "Validate an executable playbook", object_schema("id")),
        tool("execute_playbook", "Execute a bounded repository playbook", playbook_execution_schema),
        tool("playbook_status", "Read a completed playbook execution", object_schema("id"))
      ]
    end

    def call_tool(params)
      name = params.fetch("name")
      arguments = params.fetch("arguments", {})
      return super unless %w[validate_playbook execute_playbook playbook_status].include?(name)

      payload =
        case name
        when "validate_playbook" then intelligence.validate_playbook(arguments.fetch("id"))
        when "execute_playbook"
          intelligence.execute_playbook(arguments.fetch("id"), inputs: arguments.fetch("inputs", {})).to_h
        when "playbook_status" then intelligence.playbook_execution(arguments.fetch("id")).to_h
        end
      intelligence.publish(:mcp_tool_called, tool: name, read_only: name != "execute_playbook")
      { content: [ { type: "text", text: JSON.pretty_generate(payload) } ] }
    end

    private

    def playbook_execution_schema
      {
        type: "object",
        properties: { id: { type: "string" }, inputs: { type: "object" } },
        required: [ "id" ], additionalProperties: false
      }
    end
  end
end

RepositoryIntelligence::McpServer.prepend(RepositoryIntelligence::McpPlaybookTools)

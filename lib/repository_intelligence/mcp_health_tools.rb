# frozen_string_literal: true

module RepositoryIntelligence
  module McpHealthTools
    def tools
      super + [
        tool("repository_health", "Return aggregate repository health", empty_schema),
        tool("validator_list", "List registered repository validators", empty_schema),
        tool("validator_results", "Run all validators or one validator", validator_schema),
        tool("remediation_plan", "Return deduplicated remediation guidance", empty_schema),
        tool("readiness_dashboard", "Return readiness and health dashboard", empty_schema)
      ]
    end

    def call_tool(params)
      name = params.fetch("name")
      arguments = params.fetch("arguments", {})
      return super unless %w[repository_health validator_list validator_results remediation_plan readiness_dashboard].include?(name)

      payload =
        case name
        when "repository_health" then intelligence.health
        when "validator_list" then intelligence.validator_list
        when "validator_results" then intelligence.validator_results(arguments["id"]).map(&:to_h)
        when "remediation_plan" then intelligence.remediation_plan
        when "readiness_dashboard" then intelligence.readiness_dashboard
        end
      intelligence.publish(:mcp_tool_called, tool: name, read_only: true)
      { content: [ { type: "text", text: JSON.pretty_generate(payload) } ] }
    end

    private

    def validator_schema
      { type: "object", properties: { id: { type: "string" } }, additionalProperties: false }
    end
  end
end

RepositoryIntelligence::McpServer.prepend(RepositoryIntelligence::McpHealthTools)

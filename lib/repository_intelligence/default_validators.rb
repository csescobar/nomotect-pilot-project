# frozen_string_literal: true

module RepositoryIntelligence
  class DefaultValidators
    def initialize(api:, provider_status: {}, artifact_validator: nil, documentation_validator: nil)
      @api = api
      @provider_status = provider_status
      @artifact_validator = artifact_validator
      @documentation_validator = documentation_validator
    end

    def registry
      ValidatorRegistry.new
        .register(:graph_integrity, category: :architecture) { graph_integrity }
        .register(:contracts, category: :contracts) { registry_validation(api.contracts, %w[id version owns invariants]) }
        .register(:playbooks, category: :playbooks) { registry_validation(api.playbooks, %w[id version title steps completion_gate]) }
        .register(:documentation, category: :documentation) { documentation }
        .register(:documentation_governance, category: :documentation) { documentation_governance }
        .register(:contexts, category: :contexts) { artifact_sync }
        .register(:provider, category: :providers) { provider }
        .register(:security_invariants, category: :security) { invariant_presence("security") }
        .register(:privacy_invariants, category: :privacy) { invariant_presence("privacy") }
        .register(:tenant_invariants, category: :tenancy) { invariant_presence("tenant") }
        .register(:mcp, category: :mcp) { mcp }
    end

    private

    attr_reader :api, :provider_status, :artifact_validator, :documentation_validator

    def graph_integrity
      findings = []
      api.graph.edges.each do |edge|
        next if api.graph.nodes.key?(edge.from) && api.graph.nodes.key?(edge.to)

        findings << finding("error", "Edge references an unknown node", edge.to_h, "Regenerate the graph and fix scanner/provider references.")
      end
      { findings:, evidence: api.statistics }
    end

    def registry_validation(items, keys)
      findings = items.flat_map do |item|
        (keys - item.keys).map { |key| finding("error", "#{item['id'] || 'unknown'} is missing #{key}", item, "Update the versioned schema document.") }
      end
      { findings:, evidence: { entries: items.size } }
    end

    def documentation
      public_nodes = api.search(limit: 200).select { |node| %w[model controller job policy].include?(node.fetch(:type)) }
      documented = api.graph.edges.map(&:from).uniq
      missing = public_nodes.reject { |node| documented.include?(node.fetch(:id)) }
      findings = missing.first(50).map do |node|
        finding("warning", "#{node.fetch(:id)} lacks an explicit documentation edge", node, "Add or generate module documentation.")
      end
      score = public_nodes.empty? ? 100 : (((public_nodes.size - missing.size).to_f / public_nodes.size) * 100).round
      { score:, findings:, evidence: { public_nodes: public_nodes.size, undocumented: missing.size } }
    end

    def documentation_governance
      findings = Array(documentation_validator&.call).map do |message|
        finding("error", message, nil, "Update documentation ownership, sources or review deadline.")
      end
      { findings:, evidence: { governed: documentation_validator ? true : false } }
    end

    def artifact_sync
      findings = Array(artifact_validator&.call).map do |message|
        finding("error", message, nil, "Regenerate repository intelligence artifacts and commit deterministic outputs.")
      end
      { findings: }
    end

    def provider
      available = provider_status.fetch(:available, true)
      findings = available ? [] : [ finding("warning", "Configured code graph provider is unavailable", provider_status,
                                           "Install the provider or select the deterministic null provider for CI.") ]
      { findings:, evidence: provider_status }
    end

    def invariant_presence(kind)
      invariants = api.invariants(kind:)
      findings = invariants.empty? ? [ finding("warning", "No #{kind} invariants are registered", nil,
                                               "Add the invariant to a machine-readable module contract.") ] : []
      { findings:, evidence: { count: invariants.size } }
    end

    def mcp
      required = %i[graph contracts playbooks validation]
      missing = required.reject { |name| api.capabilities.key?(name) }
      findings = missing.map { |name| finding("error", "MCP dependency capability #{name} is missing", nil,
                                              "Restore the canonical RepositoryIntelligence capability.") }
      { findings:, evidence: { capabilities: api.capabilities.keys.sort } }
    end

    def finding(severity, message, evidence, remediation)
      { severity:, message:, evidence:, remediation: }
    end
  end
end

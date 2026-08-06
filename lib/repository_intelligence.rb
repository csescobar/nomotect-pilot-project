# frozen_string_literal: true

require_relative "repository_intelligence/query_engine"
require_relative "repository_intelligence/capability_registry"
require_relative "repository_intelligence/event_bus"
require_relative "repository_intelligence/playbook_executor"
require_relative "repository_intelligence/health"
require_relative "repository_intelligence/default_validators"
require_relative "repository_intelligence/documentation_governance"

module RepositoryIntelligence
  class << self
    def configure(
      graph:, contracts:, playbooks:, manifest: nil, readiness: nil, generator: nil, validator: nil,
      provider_status: {}, artifact_validator: nil, documentation_validator: nil, event_bus: EventBus.new
    )
      @graph = graph
      @contracts = contracts
      @playbooks = playbooks
      @manifest = manifest
      @readiness_report = readiness
      @generator = generator
      @validator = validator
      @provider_status = provider_status
      @artifact_validator = artifact_validator
      @documentation_validator = documentation_validator
      @event_bus = event_bus
      @query_engine = QueryEngine.new(graph:, contracts:, playbooks:)
      @playbook_executor = PlaybookExecutor.new(api: self)
      @executions = {}
      @validator_registry = DefaultValidators.new(api: self, provider_status:, artifact_validator:, documentation_validator:).registry
      register_default_capabilities
      self
    end

    def configured? = !@query_engine.nil?

    def graph = configured_value(@graph)
    def manifest = configured_value(@manifest)
    def contracts = configured_value(@contracts)
    def playbooks = configured_value(@playbooks)

    def capabilities
      require_configuration!
      @capability_registry.to_h
    end

    def capability(name)
      require_configuration!
      @capability_registry.fetch(name)
    end

    def describe_module(identifier) = query_engine.describe(identifier)
    def search(query: nil, type: nil, limit: 50) = query_engine.search(query:, type:, limit:)
    def impact_analysis(identifier, depth: 2) = query_engine.impact_analysis(identifier, depth:)
    def dependency_path(from:, to:, max_depth: 6) = query_engine.dependency_path(from:, to:, max_depth:)
    def contract(identifier) = query_engine.contract(identifier)
    def playbook(identifier) = query_engine.playbook(identifier)
    def invariants(kind: nil) = query_engine.invariants(kind:)
    def statistics = query_engine.statistics

    def validate_playbook(identifier)
      definition = identifier.is_a?(Hash) ? identifier : playbook(identifier)
      raise KeyError, "Unknown playbook: #{identifier}" unless definition

      playbook_executor.validate(definition)
    end

    def execute_playbook(identifier, inputs: {})
      definition = identifier.is_a?(Hash) ? identifier : playbook(identifier)
      raise KeyError, "Unknown playbook: #{identifier}" unless definition

      execution = playbook_executor.execute(definition, inputs:)
      @executions[execution.id] = execution
      execution
    end

    def playbook_execution(id)
      require_configuration!
      @executions.fetch(id)
    end

    def playbook_executions
      require_configuration!
      @executions.values.sort_by(&:started_at)
    end

    def generate!
      require_configuration!
      raise "generation is unavailable" unless @generator

      result = @generator.write
      event_bus.publish(:artifacts_generated, files: result.files.keys, quality: result.quality)
      result
    end

    def validate!
      require_configuration!
      findings = @validator ? Array(@validator.call) : []
      event_bus.publish(:validation_completed, findings:)
      findings
    end

    def validator_list
      require_configuration!
      @validator_registry.ids
    end

    def validator_results(id = nil)
      require_configuration!
      @validator_registry.run(id)
    end

    def health
      require_configuration!
      report = HealthAggregator.new(validator_results).to_h
      event_bus.publish(:repository_health_calculated, score: report.fetch(:score), status: report.fetch(:status))
      report
    end

    def remediation_plan
      health.fetch(:remediation)
    end

    def readiness_dashboard
      report = health
      report.merge(readiness: @readiness_report, provider: @provider_status, statistics:)
    end

    def readiness = configured_value(@readiness_report)

    def subscribe(event, callable = nil, &block)
      require_configuration!
      event_bus.subscribe(event, callable, &block)
    end

    def publish(event, payload = {})
      require_configuration!
      event_bus.publish(event, payload)
    end

    private

    attr_reader :query_engine, :event_bus, :playbook_executor

    def register_default_capabilities
      @capability_registry = CapabilityRegistry.new
        .register(:graph, description: "Normalized repository graph queries", public_methods: %i[graph search describe_module impact_analysis dependency_path statistics])
        .register(:contracts, description: "Machine-readable module and invariant contracts", public_methods: %i[contracts contract invariants])
        .register(:playbooks, description: "Versioned executable engineering playbooks", public_methods: %i[playbooks playbook validate_playbook execute_playbook playbook_execution playbook_executions])
        .register(:generation, description: "Deterministic AI artifact generation", public_methods: %i[generate!])
        .register(:validation, description: "Typed repository validators and health aggregation", public_methods: %i[validate! validator_list validator_results health remediation_plan readiness readiness_dashboard])
        .register(:events, description: "Internal repository intelligence lifecycle events", public_methods: %i[subscribe publish])
    end

    def configured_value(value)
      require_configuration!
      value
    end

    def require_configuration!
      raise "RepositoryIntelligence is not configured" unless configured?
    end
  end
end

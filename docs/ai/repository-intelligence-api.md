# Repository Intelligence Public API

`RepositoryIntelligence` is the canonical public API for repository intelligence consumers.

CLI commands, MCP resources and tools, generated AI artifacts, CI validators, and future web interfaces must depend on this façade rather than internal scanners, registries, or graph classes.

## Query operations

- `describe_module(identifier)`
- `search(query:, type:, limit:)`
- `impact_analysis(identifier, depth:)`
- `dependency_path(from:, to:, max_depth:)`
- `contract(identifier)`
- `playbook(identifier)`
- `invariants(kind:)`
- `statistics`

## Lifecycle operations

- `generate!`
- `validate!`
- `readiness`
- `subscribe(event)`
- `publish(event, payload)`

## Capabilities

The capability registry describes stable public surfaces for graph queries, contracts, playbooks, generation, validation, and lifecycle events. Internal implementation classes remain replaceable.

## Events

The initial synchronous event bus supports bounded in-process lifecycle events:

- `graph_updated`
- `artifacts_generated`
- `validation_completed`

Events are not background jobs and do not permit arbitrary execution. Subscribers are registered explicitly by trusted application code.

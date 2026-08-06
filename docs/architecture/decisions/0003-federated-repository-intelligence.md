# ADR 0003 — Federated Repository Intelligence and Governance Graph Ownership

## Status

Proposed for Epic 8 implementation.

## Context

Epic 8 introduces repository intelligence, machine-readable contracts, executable playbooks, generated architecture artifacts, readiness validation and an MCP server.

General-purpose source-code graph engines such as Codebase Memory and GitNexus already provide mature structural indexing for symbols, imports, calls, inheritance, execution paths, clusters and impact analysis. Reimplementing their parsing and indexing capabilities inside the Rails platform would duplicate substantial work, increase maintenance cost and couple the project to an incomplete in-house parser.

The platform also owns knowledge that a structural parser cannot infer reliably from code alone, including:

- epics, capabilities and delivery evidence;
- module ownership and public contracts;
- architecture dependency rules;
- security, privacy and tenant invariants;
- required tests and documentation;
- executable playbooks and completion gates;
- repository readiness and release governance.

The project needs a unified interface that combines structural code intelligence with this platform-specific governance knowledge without locking higher-level services to one external provider.

## Decision

The platform will use a federated repository-intelligence architecture.

### External structural graph providers

General-purpose source parsing and code-level graph construction will be delegated to replaceable providers behind a provider-neutral `CodeGraphProvider` contract.

The initial planned adapters are:

- Codebase Memory;
- GitNexus.

Provider-native indexes remain disposable, regenerable local caches. Their internal databases and schemas are not platform contracts.

### Platform-owned governance graph

The platform owns a normalized architecture and governance graph that enriches provider data with repository-specific concepts.

The normalized graph may contain structural nodes imported from a provider, but its defining responsibility is to represent and connect:

- modules and public contracts;
- epics and capabilities;
- security, privacy and tenant invariants;
- policies, tests and documentation;
- playbooks and completion gates;
- generated artifacts, readiness findings and delivery evidence.

Every imported or generated node and edge records provenance, extractor or provider version, source location where applicable, and the indexed commit SHA.

### Storage

Storage is divided into three tiers:

1. Provider-native local index, owned by the configured external provider and excluded from the platform's committed artifacts.
2. Local normalized SQLite query store for transactional refresh, bounded traversal and MCP or CLI queries.
3. Deterministic committed architectural snapshots in portable formats such as JSON, JSON-LD, Mermaid and Graphviz DOT.

Detailed code-level graphs may be published as CI artifacts rather than committed to the repository. The committed snapshot contains stable architectural and governance knowledge needed for review, drift detection and reproducibility.

### Updating and freshness

Local development may use incremental refresh based on the indexed commit and changed files. Extractors replace the nodes and edges they own for affected files and remove data for deleted files.

Git hooks may mark an index as stale but must not silently claim freshness or require a full graph rebuild during every commit.

CI is authoritative and always performs a clean regeneration. CI validates that provider metadata, normalized graph data and committed artifacts refer to the same source commit and that deterministic outputs have not drifted.

### Shared application services

CLI commands, CI validators, generated documentation and the MCP server consume shared repository-intelligence application services. The MCP server is an adapter and must not implement a separate graph or parsing pipeline.

### MCP boundaries

MCP resources, tools and prompts expose bounded operations over the shared intelligence services.

The MCP server is read-only by default and does not expose arbitrary shell commands, SQL execution, Ruby evaluation, unrestricted filesystem writes, Git publishing, merging, deployment or secret retrieval.

Generated-file writes require an explicit capability and remain restricted to allowlisted repository paths.

## Consequences

### Positive

- Avoids duplicating mature source-code parsing and graph-indexing work.
- Allows Codebase Memory, GitNexus or future providers to be replaced without rewriting higher-level AI services.
- Keeps platform-specific governance knowledge under repository control.
- Supports deterministic CI rebuilds and reviewable committed snapshots.
- Gives MCP clients one normalized interface for structural and governance impact analysis.
- Separates disposable local query indexes from portable architectural evidence.

### Negative

- Provider adapters require compatibility testing and capability negotiation.
- Different providers may expose unequal graph depth or semantics.
- Normalization can lose provider-specific features unless optional capabilities are preserved explicitly.
- Incremental refresh is more complex because provider and platform extractor freshness must be reconciled.
- Developers need at least one supported external provider for complete structural intelligence.

## Rejected alternatives

### Build a general-purpose parser and code graph in Rails

Rejected because it duplicates specialized Tree-sitter-based tools, creates a large multi-language maintenance burden and distracts the platform from its unique governance responsibilities.

### Depend directly on one provider throughout the platform

Rejected because it creates vendor and schema lock-in and makes CLI, CI, documentation and MCP behavior depend on provider-specific implementation details.

### Store the complete graph only as committed JSON

Rejected because large code-level graphs are inefficient for local traversal, difficult to update transactionally and noisy in source control.

### Require a dedicated remote graph database

Rejected for the initial baseline because it adds infrastructure and deployment complexity before SQLite traversal limits are demonstrated.

## Validation

This decision is validated when Epic 8 demonstrates:

- at least two provider adapters or one production adapter plus a contract-complete fixture adapter;
- the same normalized graph schema across providers;
- deterministic clean generation in CI;
- freshness and provenance tied to the source commit;
- local SQLite queries and portable snapshot exports;
- shared services used by CLI, CI and MCP;
- integration tests proving provider replacement does not change governance contracts.

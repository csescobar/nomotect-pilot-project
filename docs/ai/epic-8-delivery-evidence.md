# Epic 8 Delivery Evidence

## Delivered in PR #24

### Repository intelligence foundation

- Provider-neutral `CodeGraphProvider` result contract.
- Deterministic null provider for CI and environments without external tooling.
- Command-backed Codebase Memory and GitNexus adapters with capability and version detection.
- Root-bounded manifest generation with file classification and SHA-256 source hashes.
- Source commit synchronization and provider provenance metadata.
- Clean deterministic generation in GitHub Actions.

### Federated governance graph

- Stable node and edge records.
- Structural extraction for models, controllers, jobs, policies, components, tests and documentation.
- Provider node and edge normalization.
- Test and documentation evidence relationships.
- Bounded recursive impact analysis.
- Graph integrity validation for missing nodes, duplicate edges and self-references.
- Graph diff service for added and removed nodes and edges.

### Storage and distribution baseline

- Deterministic JSON architecture manifest.
- Normalized graph JSON.
- JSON-LD, Mermaid and Graphviz DOT exports.
- SHA-256 snapshot checksums and schema versions.
- Detailed graph artifacts uploaded by GitHub Actions.

### Contracts and playbooks

- Versioned YAML module contract and JSON Schema.
- Allowed and forbidden dependency declarations.
- Security, privacy and repository-invariant declarations.
- Versioned cross-vendor playbook schema.
- Feature, bug-fix, refactoring, security-review and release-readiness playbooks.
- Safe declarative execution boundary without arbitrary shell, SQL or Ruby evaluation.

### MCP server

- Stdio JSON-RPC transport.
- MCP initialization and capability discovery.
- Manifest, graph, contracts and readiness resources.
- Node description, bounded impact analysis and readiness tools.
- Playbooks exposed as MCP prompts.
- Read-only default behavior and fixed resource/tool registry.
- Integration tests for initialization, resources and tools.

### Readiness pipeline

- Contract and playbook validation.
- Graph integrity and commit freshness validation.
- Deterministic generation quality gate.
- Repository readiness report.
- `bin/ci` integration.
- GitHub Actions repository-intelligence artifact.
- Fully green CI run #156 for the implementation head before this evidence update.

## Explicitly remaining

Epic 8 remains partially delivered until these expanded-roadmap capabilities are implemented or formally deferred:

- true changed-file incremental extraction and transactional replacement;
- a local normalized SQLite query store;
- committed snapshot drift comparison against a clean rebuild;
- broader Rails extraction for routes, views, operations, queries, domain events and explicit governance nodes;
- generated module AI contexts and generated public-contract documentation;
- executable playbook stages beyond declarative MCP prompts;
- MCP repository search, dependency paths, generation/validation tools, structured audit events, output limits and execution timeouts;
- breaking-change detection for public contracts;
- full architecture, documentation and AI-context drift validation.

The roadmap must remain `◐ Partially delivered` until the remaining list is resolved. A green CI run proves the delivered baseline; it does not waive the remaining completion criteria.

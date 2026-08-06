# Expanded MCP Interface

Epic 8 Phase 5 exposes repository intelligence as semantic MCP resources, tools and prompts over the canonical `RepositoryIntelligence` facade.

## Resources

The server exposes manifests, the normalized graph, capability and statistics reports, contracts, playbooks, provider diagnostics, readiness, structured request audit entries and generated artifacts under the allowlisted repository-intelligence output directory.

## Semantic tools

Tools describe modules, contracts and playbooks; search repository knowledge; find tests and documentation; calculate impact and directed dependency paths; retrieve invariants and statistics; inspect provider health; validate the repository; and, when explicitly enabled, regenerate deterministic artifacts.

## Security boundaries

- The server is read-only by default.
- Generated-file writes require `MCP_ALLOW_WRITES=true`.
- No tool accepts arbitrary shell, SQL or Ruby evaluation.
- Generated-artifact paths are restricted to the configured output root.
- Requests use bounded inputs, a configurable request budget and execution timeout.
- Every completed, rejected or failed MCP operation is recorded in a bounded structured audit log and emitted through the repository-intelligence event bus.

## Operations

Start the local stdio server with:

```bash
ruby bin/repository-intelligence mcp
```

Enable deterministic generated-file writes only in a trusted local environment:

```bash
MCP_ALLOW_WRITES=true ruby bin/repository-intelligence mcp
```

Remote transport remains deferred until authenticated client, authorization and deployment contracts are defined.

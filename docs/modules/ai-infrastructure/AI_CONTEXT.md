# AI Infrastructure Context

## Purpose

Provide deterministic repository intelligence, governance graphs, executable playbooks and a vendor-neutral MCP interface without duplicating a general-purpose source-code parser.

## Architectural invariants

- Structural code intelligence comes from replaceable `CodeGraphProvider` adapters.
- The platform owns normalized governance knowledge, stable identifiers, provenance, contracts and readiness evidence.
- The null provider must keep generation functional when external providers are unavailable.
- Generated artifacts identify the source commit and are reproducible from repository content.
- MCP is read-only by default and exposes only registered resources, tools and prompts.
- Graph traversal is bounded and never accepts arbitrary code, shell, SQL or Ruby evaluation.
- Repository file discovery is root-bound and rejects symlink escapes.
- Provider-native indexes are disposable caches and are not the canonical governance record.

## Owned contracts

- `RepositoryIntelligence::CodeGraphProvider`
- `RepositoryIntelligence::ManifestGenerator`
- `RepositoryIntelligence::GovernanceGraph`
- `RepositoryIntelligence::GovernanceScanner`
- `RepositoryIntelligence::ContractRegistry`
- `RepositoryIntelligence::PlaybookRegistry`
- `RepositoryIntelligence::ReadinessReport`
- `RepositoryIntelligence::McpServer`

## Provider integration

`CODE_GRAPH_PROVIDER` accepts `null`, `codebase_memory` or `gitnexus`. External adapters must return normalized `nodes` and `edges` JSON where possible. Provider failures must fail explicitly rather than silently returning stale data.

## Security boundaries

- Never expose environment variables, credentials, arbitrary repository paths or unrestricted file contents.
- Keep MCP tool inputs schema-bound and traversal depth capped.
- Generated-file writes are performed only through the repository-intelligence CLI.
- Remote MCP transport is outside this baseline and requires separate authentication and authorization design.

## Required verification

Run:

```bash
ruby bin/repository-intelligence generate
ruby bin/repository-intelligence validate
ruby bin/repository-intelligence mcp
bash bin/ci
```

Changes to graph schemas, contracts, providers, MCP resources or playbooks require unit tests and final green GitHub Actions evidence.

# AI-First Architecture

This directory defines the repository contracts that make Rails Hotwire Platform understandable and extensible without requiring proprietary memory systems or a specific coding agent.

Agents beginning an adoption journey must complete the
[Antigravity CLI MCP setup](mcp-setup.md) through the root-level
[`MCP_BOOTSTRAP.md`](../../MCP_BOOTSTRAP.md) entrypoint before broad repository
discovery.

## Artifacts

- `module-contract-specification.md` — required human-readable contract for each platform module
- `contribution-boundaries.md` — classification of files by modification risk and review requirements
- `architecture-manifest.schema.json` — initial machine-readable architecture manifest schema
- `templates/AI_CONTEXT.md` — module context template
- `commands/` — repeatable implementation playbooks for humans and agents
- `ai-first-roadmap.md` — staged implementation plan

## Design rule

Machine-readable metadata supplements source code, tests and documentation. It never overrides runtime authorization, security controls or human review.

## Vendor neutrality

The contracts must be usable by command-line agents, IDE assistants, code search tools and human contributors. No required artifact may depend on one AI provider.

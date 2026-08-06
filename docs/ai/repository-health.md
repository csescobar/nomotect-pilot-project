# Repository Health and Readiness

Epic 8 Phase 7 introduces a shared health model for repository intelligence.

Each validator returns a category, status, score, typed findings, evidence, and remediation guidance. The health aggregator produces one deterministic dashboard with:

- an overall score from 0 to 100;
- `healthy`, `degraded`, or `unhealthy` status;
- category scores and validator status;
- evidence-backed findings;
- a deduplicated remediation plan;
- repository readiness, provider diagnostics, and graph statistics.

Built-in validation categories include architecture, contracts, playbooks, documentation, generated contexts, provider connectivity, MCP capabilities, security, privacy, and tenancy invariants.

## CLI

```bash
ruby bin/repository-intelligence health
ruby bin/repository-intelligence readiness
ruby bin/repository-intelligence validators
ruby bin/repository-intelligence validators graph_integrity
```

## MCP

The MCP server exposes `repository_health`, `validator_list`, `validator_results`, `remediation_plan`, and `readiness_dashboard` as read-only semantic tools.

The health model is the canonical source for a future Rails administration dashboard. Presentation layers must not calculate independent scores.

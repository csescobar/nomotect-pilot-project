# AI-First Implementation Roadmap

## Phase 1 — Contracts

- Establish platform vision and AI-first principles
- Define contribution boundaries
- Define module context contracts
- Publish the architecture manifest schema
- Add vendor-neutral command playbook conventions

## Phase 2 — Module context

- Add `AI_CONTEXT.md` to every core module
- Link each context to ADRs, tests and public APIs
- Validate required sections in CI
- Add context freshness checks to pull requests

## Phase 3 — Machine-readable architecture

- Create `architecture.json`
- Validate it against the published schema
- Generate dependency diagrams
- Detect forbidden module dependencies
- Expose public APIs and ownership metadata

## Phase 4 — Executable playbooks

- Implement the first playbooks for modules, components, grids and CRUD flows
- Connect playbooks to Rails generators where appropriate
- Ensure generated code includes tests, i18n and documentation hooks

## Phase 5 — Automated review evidence

- Add CI checks for architecture contracts
- Produce security, privacy and accessibility check summaries
- Detect missing translations and documentation
- Report dependency and contract changes in pull requests

## Phase 6 — AI readiness assessment

Define measurable indicators for:

- Contract coverage
- Documentation freshness
- Test coverage of public behavior
- Architectural dependency compliance
- Security and privacy evidence
- Accessibility validation
- Observability coverage

The assessment must report evidence and gaps. It must not present a single score as proof of software quality.

## Phase 7 — Tool integrations

Offer optional adapters for codebase indexing, knowledge graphs and memory tools while keeping repository-native contracts as the source of truth.

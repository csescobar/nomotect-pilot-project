# Agent Instructions

These instructions define how agents work in NomoTect. All AI-assisted contributions must comply with the [NomoTect Agent Directive](docs/architecture/AGENTS.md), [AI_PRINCIPLES.md](AI_PRINCIPLES.md), [VISION.md](VISION.md) and the contracts under [`docs/ai`](docs/ai/README.md).

## Branch and pull request workflow

- Never commit directly to `main`.
- Create a focused branch using the `agent/<description>` naming pattern.
- Keep changes limited to the approved scope.
- Open a draft pull request unless the user explicitly requests a ready-for-review pull request.
- Use English for repository content, comments, commit messages, issues and pull requests.

## Context discovery

Before changing a platform module:

1. Read its `AI_CONTEXT.md` when present.
2. Read linked ADRs and public API documentation.
3. Identify the contribution boundary defined in `docs/ai/contribution-boundaries.md`.
4. Inspect canonical tests and examples.
5. State any missing or contradictory context rather than guessing.

Repository-native contracts are the source of truth. External codebase-memory or indexing tools may assist discovery but must not override repository contracts.

## Architecture

- Determine the contribution mode before editing:
  - **Platform contribution:** maintainers may change shared `app/`, `config/`, `lib/`, `test/` and documentation paths when the task explicitly evolves NomoTect and satisfies the applicable review boundary.
  - **Application development:** product-specific code belongs under `/application` and must use documented platform contracts rather than editing shared internals.
- Keep domain logic independent of Rails controllers, Turbo and HTML.
- Controllers call application operations.
- State changes use explicit domain methods.
- Never bypass authorization or tenant scoping.
- Never construct SQL from client-provided identifiers.
- Preserve module boundaries and avoid speculative abstractions.
- Update module contracts when public APIs, invariants, dependencies or extension points change.
- Do not confuse `/application` with the `Installation` namespace used by the first-run installer.

## Required validation

Before completing a change, run the future project entrypoint:

```bash
bin/ci
```

Until application code exists, verify Markdown, JSON, internal links and configuration examples manually.

## Documentation

- Add or update an ADR for significant decisions.
- Update the module catalog when introducing a capability.
- Document security, privacy, accessibility and migration impact.
- Add i18n keys for all user-facing text.
- Do not document behavior that has not been implemented or formally planned.
- Keep `AI_CONTEXT.md` and machine-readable architecture metadata synchronized with supported behavior.

## Security

- Do not log secrets, tokens, passwords or unnecessary personal data.
- Use server-side whitelists for grid fields and operators.
- Ensure tenant scope is applied before user-controlled query options.
- Treat uploads, exports, integrations and rich text as security-sensitive surfaces.

## Completion report

When finishing work, summarize:

- Branch and pull request.
- Files and behavior changed.
- Contracts or boundaries affected.
- Validation performed.
- Known limitations or follow-up work.

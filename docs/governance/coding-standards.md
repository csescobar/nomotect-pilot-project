# Coding Standards

## Language and communication

- Repository content, code comments, commit messages, issues and pull requests are written in English.
- User-facing copy must use Rails I18n rather than hard-coded text.
- Names should reflect domain language and avoid unexplained abbreviations.

## Ruby and Rails

- Follow the supported Ruby and Rails conventions unless an ADR explicitly overrides them.
- Prefer small objects with one clear responsibility.
- Keep controllers focused on HTTP concerns and delegation.
- Use explicit domain methods for meaningful state transitions.
- Keep transaction boundaries in application operations.
- Use callbacks only for small, local and predictable lifecycle behavior.
- Avoid concerns that obscure unrelated behavior behind broad mixins.

## Hotwire and presentation

- Turbo and Stimulus belong to the presentation layer.
- Domain models must not depend on Turbo frame identifiers, stream actions or HTML partials.
- Prefer semantic server-rendered HTML and progressive enhancement.
- Stimulus controllers should be small, lifecycle-safe and cleaned up on disconnect.

## Data access

- Scope queries by tenant and authorization before applying user-controlled filtering.
- Use parameterized queries and internal whitelists for identifiers.
- Enforce critical integrity rules with database constraints.
- Avoid N+1 queries and unbounded collection loading.
- Migrations must be reversible or include a documented rollback strategy.

## Components

- UI components consume design tokens rather than hard-coded visual values.
- Components must define accessible states for focus, disabled, loading, error and empty conditions.
- Component APIs should be stable, documented and covered by previews or showcase examples.

## Grid subsystem

- Column types own default operators, parsers, filter controls and formatters.
- Individual columns declare semantic meaning and only override type behavior exceptionally.
- The client never submits raw SQL or database identifiers.
- The grid query protocol remains independent of the visual adapter.

## Tests and quality

- Use TDD where practical and always add regression tests for defects.
- Test domain rules separately from delivery mechanisms.
- Include integration tests for authorization, tenant isolation and advanced grid queries.
- Keep tests deterministic and avoid unnecessary mocks.
- Run the project validation entrypoint before requesting review.

## Security and privacy

- Apply least privilege and deny by default.
- Never expose secrets or unnecessary personal data in logs, errors or fixtures.
- Audit sensitive state changes and data exports.
- Validate file type, size, authorization and storage policy for uploads.
- Document security and privacy impact in every relevant pull request.

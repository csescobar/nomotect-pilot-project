# AI Contribution Principles

This document defines the quality, safety and governance standards for contributions created or materially assisted by AI agents.

`AGENTS.md` describes how an agent operates in this repository. This document defines what an acceptable AI-assisted contribution must achieve.

## Human accountability

- AI assistance does not transfer accountability away from the contributor or reviewer.
- Generated code, tests, migrations and documentation must be reviewed as if they were written manually.
- Unverified claims, fabricated APIs and speculative security guarantees are prohibited.
- Material uncertainty must be documented in the pull request.

## Architecture

- Preserve the modular monolith and explicit module boundaries.
- Keep domain rules independent of controllers, Turbo, HTML and external delivery mechanisms.
- Use application operations to coordinate transactions, authorization, auditing and side effects.
- Prefer explicit domain methods over direct mutation of meaningful state.
- Introduce abstractions only when they solve a demonstrated problem.

## Security and privacy

- Treat all external input as untrusted.
- Never generate SQL, file paths, commands or constant names directly from client-controlled identifiers.
- Apply authorization and tenant scope before filtering, sorting, exporting or serializing data.
- Do not log secrets, credentials, session values or unnecessary personal data.
- Security controls must fail closed.
- Changes affecting authentication, authorization, cryptography, uploads, exports or audit trails require focused security tests.

## Testing

- Generated behavior must be covered at the lowest useful test level.
- Every defect fix must include a regression test.
- Critical domain invariants require direct tests and database constraints where appropriate.
- Tests must not be weakened merely to make generated code pass.
- Flaky tests must be investigated, not retried indefinitely or silently disabled.

## Internationalization and accessibility

- User-facing text must use translation keys.
- Components must support the documented locales and localized formatting rules.
- Interactive behavior must remain keyboard accessible.
- Semantic HTML is preferred over compensating with ARIA.
- Focus management, validation announcements and contrast must be considered for dynamic Turbo updates.

## Performance and operations

- Avoid unbounded queries, N+1 access patterns and loading complete datasets into memory.
- Grid filtering, sorting, pagination and exports must remain server-controlled and bounded.
- Background jobs must define retry, idempotency and failure behavior.
- Operational events must include correlation identifiers without exposing sensitive payloads.

## Dependencies

- Prefer mature, actively maintained, permissively licensed open-source dependencies.
- A new dependency must justify why the standard library or existing platform capability is insufficient.
- Do not introduce paid-only behavior into a core platform contract.
- Dependency additions require license, maintenance and security review.

## Documentation and traceability

- Significant decisions require an ADR.
- Pull requests must explain security, privacy, data migration and rollback implications.
- Generated documentation must describe actual behavior, not intended behavior that does not yet exist.
- Public contracts, configuration formats and extension points must be documented and versioned.

## Review requirements

Reviewers should confirm that an AI-assisted contribution:

1. Solves the stated problem without unrelated expansion.
2. Preserves module boundaries and domain invariants.
3. Includes meaningful tests and validation evidence.
4. Does not introduce hidden security or privacy regressions.
5. Uses existing conventions before creating new ones.
6. Updates documentation and translations where needed.
7. Can be understood and maintained without relying on the original prompt or agent session.

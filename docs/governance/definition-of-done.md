# Definition of Done

A change is complete when all applicable items have evidence.

## Required

- Scope and acceptance criteria are satisfied.
- Tests cover the changed behavior and important failure paths.
- Authorization and tenant scope are verified.
- User-controlled input is validated and safely encoded.
- No secrets or unnecessary personal data are logged.
- User-facing text is internationalized.
- Accessibility impact is reviewed.
- Structured logs, metrics or traces are added where operationally relevant.
- Documentation, examples and module AI context are current.
- Database migrations are safe, reversible where practical and documented.
- Dependency additions are justified and reviewed.
- `bin/ci` passes when the executable project provides it.

## Conditional

Security-sensitive, architectural or cross-module changes also require threat analysis, an ADR or RFC, migration guidance and explicit rollback planning.

Any intentionally deferred item must be recorded with an owner and follow-up issue.
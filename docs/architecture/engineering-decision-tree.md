# Engineering Decision Tree

## Purpose

Provide a shared architectural navigation path for recurring implementation decisions.

## New capability

1. Does the capability belong to an existing module?
   - Yes: extend that module through its public contract.
   - No: propose a module through an RFC.
2. Is it a state-changing use case?
   - Use an application operation and explicit domain behavior.
3. Is it a read-only use case?
   - Use a query object or read model.
4. Does it cross a module boundary?
   - Use a documented operation, query contract or domain event.
5. Does it expose user-facing HTML?
   - Use ViewComponent and Rails I18n; add Turbo only as progressive enhancement.
6. Does it display tabular data?
   - Use the Grid DSL and server-validated query contract.
7. Does it handle personal or sensitive data?
   - Add privacy, authorization, audit and retention analysis.
8. Does it run asynchronously?
   - Define idempotency, retry, timeout, tenant context and observability.
9. Does it add a dependency or public API?
   - Record alternatives, compatibility and exit strategy.
10. Is the decision difficult to reverse or platform-wide?
    - Write an RFC and ADR before implementation.

## Completion

Apply the Definition of Done and update module AI context, architecture manifests and user documentation as applicable.
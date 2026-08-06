# Architecture

## Purpose

Define the stable architectural shape of Rails Hotwire Platform and the rules that protect its modularity.

## Architectural style

The platform starts as a modular monolith. Modules own cohesive capabilities and expose explicit public contracts. Distribution into gems or services is deferred until boundaries are proven through use.

## Primary layers

- **Presentation:** controllers, Turbo responses, ViewComponents, Stimulus controllers and HTML.
- **Application:** operations, commands, queries, transaction boundaries and orchestration.
- **Domain:** entities, value objects, aggregates, policies, domain services and events.
- **Infrastructure:** Active Record persistence, jobs, mail, files, integrations, logging and telemetry.

Dependencies point inward. Presentation and infrastructure may depend on application and domain contracts. Domain code must not depend on presentation technology.

## Platform modules

Core modules include identity, authorization, tenancy, audit, privacy, design system, grid, workflows, notifications, files, integrations, observability and developer experience.

Each implemented module must contain or reference:

- a public contract;
- an `AI_CONTEXT.md`;
- owned data and invariants;
- allowed dependencies;
- authorization and tenant rules;
- tests and operational signals;
- extension and migration guidance.

## Architectural invariants

- Controllers do not implement business rules.
- State transitions use explicit domain methods or application operations.
- Turbo remains a presentation concern.
- Tenant scope is applied before user-controlled filtering, sorting or lookup.
- Client-provided identifiers never become unchecked SQL identifiers.
- Critical asynchronous publication uses durable delivery patterns such as an outbox.
- Framework callbacks may normalize local state but must not hide business workflows.
- Public APIs and DSLs are versioned contracts.

## Evolution

A module may be extracted only when it has a stable contract, independent tests, observable behavior and a demonstrated deployment or reuse need. Extraction is a consequence of maturity, not an initial objective.
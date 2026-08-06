# Platform Architecture

## Architectural style

The platform starts as a modular monolith. Modules communicate through explicit application operations and domain events, not through uncontrolled cross-module persistence access.

```text
Presentation
  Controllers, Turbo Streams, ViewComponents, Stimulus
        ↓
Application
  Commands, queries, operations, transaction boundaries
        ↓
Domain
  Entities, value objects, aggregates, policies, domain services, events
        ↓
Infrastructure
  Active Record, jobs, mail, files, external APIs, audit, telemetry
```

## Core rules

- Turbo and HTML remain in the presentation layer.
- Controllers coordinate HTTP behavior and call application operations.
- Business state changes use explicit domain methods.
- Authorization and tenant scope are applied before user-controlled queries.
- Critical events use durable delivery patterns such as a transactional outbox.
- Cross-domain dependencies must be explicit and documented.

## Platform modules

```text
platform/
├── core
├── design_system
├── grid
├── identity
├── authorization
├── audit
├── privacy
├── observability
├── integrations
├── workflows
├── files
├── notifications
├── multi_tenancy
├── i18n
└── developer_experience
```

## Evolution strategy

The reference application will validate the architecture first. Stable modules may later be extracted into versioned gems so derived applications can receive upgrades and security fixes without manual file copying.

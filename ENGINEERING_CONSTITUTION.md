# Engineering Constitution

## Purpose

This document is the highest-level engineering authority for Rails Hotwire Platform. It defines the commitments that guide architecture, contribution, operation and evolution.

## Mission

Build an AI-native enterprise engineering platform that helps humans and coding agents create secure, governed, accessible and maintainable Rails applications.

## Constitutional principles

### AI-native

The repository must be understandable without proprietary memory tooling. Architecture, invariants, extension points and workflows must be represented in repository-native documentation and machine-readable contracts.

### Enterprise-ready

Security, privacy, governance, observability, internationalization, accessibility and maintainability are design inputs, not post-release enhancements.

### Frameworks are adapters

Domain and application behavior must not depend on Turbo, HTML, controllers, background job providers or third-party UI libraries. Framework integrations remain replaceable boundaries.

### Explicit architecture

Important behavior must be easy to locate. Hidden workflows, uncontrolled callbacks, implicit tenant scope and client-defined SQL are prohibited.

### Open community core

The community repository is licensed under Apache License 2.0 and must remain capable of supporting serious business applications. A separate commercial repository may provide premium integrations, operational tooling and enterprise services.

### Human accountability

AI assistance does not replace ownership, review, security analysis or evidence. Contributors remain accountable for submitted changes.

## Quality definition

A change is not complete merely because it runs. Completion requires appropriate evidence across architecture, tests, security, privacy, i18n, accessibility, observability, documentation and migration safety.

## Decision hierarchy

When guidance conflicts, apply this order:

1. Applicable law and security obligations
2. This Engineering Constitution
3. Accepted ADRs
4. Architecture and governance standards
5. Module contracts and AI context
6. Implementation conventions

Exceptions require an ADR that identifies the conflict, scope, risks and removal plan.

## Long-term commitments

- Preserve stable extension points.
- Prefer incremental modular evolution over premature distribution.
- Keep dependencies intentional and replaceable.
- Maintain English as the repository language.
- Keep public contracts documented and versioned.
- Protect tenant boundaries and personal data by default.
- Preserve accessible server-rendered behavior where practical.

## Non-goals

The platform is not intended to:

- Replace Rails conventions without demonstrated value.
- Become a universal abstraction over every Ruby library.
- Hide business rules inside framework callbacks.
- Require a specific AI vendor or agent product.
- Guarantee regulatory certification solely through framework adoption.
- Move essential community capabilities into the commercial repository.

## Amendment process

Material changes require an RFC, explicit impact analysis and an accepted ADR. Constitutional changes must be highlighted in the pull request summary.
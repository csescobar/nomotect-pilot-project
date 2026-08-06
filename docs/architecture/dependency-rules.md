# Dependency Rules

## Purpose

Prevent accidental coupling between platform modules and layers.

## Layer rules

- Domain objects may depend on Ruby and domain-local abstractions only.
- Application operations may depend on domain contracts and injected ports.
- Infrastructure implements ports and may depend on Rails and third-party libraries.
- Presentation may call application operations and read query results.
- Presentation-specific objects must not be passed into domain behavior.

## Module rules

- Cross-module writes occur through public operations or events.
- Cross-module reads use documented query contracts.
- Direct access to another module's internal tables or private classes is prohibited.
- Circular module dependencies are prohibited.
- Shared code must represent a stable platform concept, not merely duplicated convenience.

## Application-layer rules

- Product-specific source belongs under `/application`.
- `/application` may depend on documented platform contracts.
- Platform modules must not reference product-specific constants, files or database tables directly.
- Discovery flows through reviewed bootstrap and registration APIs; it must not scan arbitrary Ruby constants or execute unvalidated paths.
- The `Installation` namespace remains a platform provisioning capability and is not an application-layer alias.

## Enforcement roadmap

Initially these rules are enforced by review and module contracts. Later phases will add automated dependency validation, architecture manifest checks and boundary tests.

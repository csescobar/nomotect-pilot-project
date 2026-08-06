# Contribution Boundaries

Repository areas are classified by modification risk. The classification applies equally to human-authored and AI-assisted changes.

## Ownership and contribution mode

- **Platform-owned:** shared `app/`, `config/`, `lib/`, `test/` and platform documentation. These paths may change during an explicitly scoped platform contribution at the review level below.
- **Application-owned:** product-specific code under `/application`. Application development must not edit platform-owned paths to add roles, grids, policies, views, routes or domain behavior.
- **First-run installation:** the platform `Installation` namespace and installation wizard. This is not the application-owned layer.

AI assistance does not determine ownership. Reusability and the declared task mode determine whether behavior belongs to the platform or to a particular product.

## Standard

Routine changes following documented extension points.

Examples:

- New translations
- New showcase examples
- New product modules under `/application` using established generators and public registration surfaces
- Tests for existing public behavior

Required evidence: relevant tests and documentation updates.

## Review required

Changes that affect shared contracts or cross-cutting behavior.

Examples:

- Shared ViewComponents
- Grid types, operators and adapters
- Authorization policies
- Tenant scoping
- Logging and audit infrastructure
- Public configuration formats

Required evidence: tests, security and privacy assessment, compatibility assessment and maintainer review.

## Architecture review required

Changes that alter platform boundaries or foundational guarantees.

Examples:

- Authentication and session handling
- Cryptography and secret management
- Domain transaction boundaries
- Dependency direction
- Architecture manifest schema
- Module public APIs
- Data retention and deletion behavior
- Generated-code templates
- Application-layer bootstrap and loading
- Application-owned role, grid, route or extension registration APIs

Required evidence: ADR, threat analysis, migration or rollback plan and maintainer approval.

## Generated

Generated files must not be edited manually unless their generator explicitly supports it. Generated files must contain a header identifying the source generator where appropriate.

## Prohibited without explicit authorization

- Disabling security controls to make tests pass
- Bypassing tenant scope or authorization
- Logging secrets or unnecessary personal data
- Executing client-provided SQL or constant names
- Adding hidden network calls or telemetry
- Introducing proprietary dependencies as mandatory platform infrastructure
- Direct commits to `main`
- Product-specific behavior added outside `/application`
- Platform code depending on product-specific constants or files

## Pull request declaration

Every pull request should state:

- Which boundary level applies
- Whether AI assistance was used
- Which contracts changed
- Security, privacy and accessibility impact
- Validation performed

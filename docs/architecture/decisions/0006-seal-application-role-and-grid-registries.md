# ADR 0006 — Seal Application Role and Grid Registries

## Status

Accepted

## Context

The `/application` boundary needs product-owned roles and grids without requiring edits to shared platform files. Roles affect authorization, and every Grid Engine definition must be paired with a tenant-authorized relation. Mutable runtime registries or convention-based discovery would make these guarantees difficult to review and could allow protected behavior to be replaced.

## Decision

Load exactly `application/config/roles.rb` and `application/config/grids.rb` during Rails initialization. These files may use the public `ApplicationRoles.register` and `GridEngine::Catalog.register` APIs.

Core roles and grids are registered first and cannot be replaced. Custom roles contain explicit permission keys and receive no implicit administrative privilege. Every grid registration contains both its definition and a callable authorized scope. After both fixed files load, the registries are sealed and reject further mutation.

Policies remain the enforcement boundary. `Membership#permitted?` exposes registered permissions to policies, controllers enforce policy queries with `authorize!`, and views may mirror the same result through `allowed_to?`.

## Alternatives considered

### Scan application directories automatically

Rejected because file discovery would be less explicit, harder to review and more sensitive to naming and load-order changes.

### Let application code edit shared registries

Rejected because it breaks the ownership boundary and makes platform upgrades conflict with product behavior.

### Infer grid scope from the model

Rejected because a model relation is not proof of tenant authorization.

## Consequences

- Product roles and grids use two small, fixed and reviewable configuration files.
- Invalid, duplicate, late or unscoped registrations fail during startup.
- Application policies can consume explicit role permissions without changing shared role constants.
- Adding a role requires locale labels and policy tests; adding a grid requires tenant-isolation tests for its scope.

## Security and privacy

The sealed registries prevent runtime replacement of protected entries. Explicit grid scopes preserve tenant-first authorization and avoid deriving relations from request input. Registrations store configuration and permission identifiers, not personal data.

## Migration and rollback

No database migration is required. Existing `owner`, `admin` and `member` values retain their behavior. Rollback removes the initializer and registration APIs; product configuration must be removed at the same time because startup would no longer load it.

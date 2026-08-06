# ADR 0005 — Use `/application` as the Product Application Layer

## Status

Accepted

## Context

NomoTect is both a reusable governed platform and the foundation for separately owned products. The existing agent directive referred to an `/installation` write boundary that did not exist in the repository and conflicted with the platform's established `Installation` namespace for first-run provisioning. It also failed to distinguish platform maintenance from product-specific generation, causing valid shared-platform changes to be reported as boundary violations.

Product teams need a stable location for models, controllers, operations, policies, helpers, views, jobs, routes, roles, grids, migrations, extensions and tests without editing protected platform internals.

## Decision

Use `/application` as the repository root for product-specific application code. Reserve the `Installation` namespace and installation documentation for first-run platform provisioning.

The future application layer will mirror the relevant Rails structure:

```text
application/
├── app/
│   ├── controllers/
│   ├── helpers/
│   ├── jobs/
│   ├── models/
│   ├── operations/
│   ├── policies/
│   └── views/
├── config/
│   ├── initializers/
│   ├── locales/
│   ├── grids.rb
│   ├── roles.rb
│   └── routes/application.rb
├── db/migrate/
├── extensions/
└── test/
```

The directory is an ownership boundary, not a mandatory Ruby namespace. Product classes may use normal domain names while their source remains application-owned.

Dependencies flow from `/application` to documented platform contracts. Platform code must not depend directly on product constants. The platform may load application code only through a small reviewed bootstrap and explicit registration surfaces.

Two contribution modes apply:

1. A platform contribution may change shared paths when the request explicitly evolves NomoTect and the required review is satisfied.
2. Application development places product-specific behavior under `/application` and does not edit shared platform internals.

## Alternatives considered

### `/installation`

Rejected because it conflates product ownership with first-run installation, conflicts with the existing `Installation` namespace and provides no useful description after provisioning is complete.

### Continue placing product code in shared Rails paths

Rejected because platform upgrades cannot reliably distinguish reusable framework changes from private product behavior.

### Require a Ruby namespace for all product code

Rejected as a universal rule because the ownership boundary can be enforced through paths and registration without imposing product naming. Products may still choose namespaces for their own domains.

## Consequences

- The Application Starter must create and preserve the `/application` skeleton.
- Rails bootstrap, routes, views, locales, migrations and tests are integrated through explicit native Rails paths.
- Rails bootstrap uses explicit native paths and a fixed `draw :application` route file; it does not scan arbitrary executable paths.
- Roles and grids require explicit application-owned registration APIs.
- Policies, helpers and operations can be product-owned without shared-core edits.
- Repository Intelligence and CI must classify and validate the new boundary.
- Existing generic platform behavior remains in shared paths; it is not moved solely because AI assisted its creation.

## Security and privacy

The boundary does not grant application code additional trust. Tenant scope, authorization, input validation, secret handling and privacy minimization remain platform contracts. Registrations must be allowlisted, deterministic and unable to replace protected ownership or security behavior.

## Migration and rollback

The boundary requires no data migration. Runtime adoption is delivered through separate reviewable changes. Before product migrations or source are added, the bootstrap can be rolled back by removing its Rails paths, route draw, CI target and tracked skeleton.

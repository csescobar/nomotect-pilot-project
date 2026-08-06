# Multi-Tenant Request and Job Context

## Request resolution

Authenticated requests resolve the active tenant through the signed-in user's current memberships.

Resolution order:

1. an explicit organization slug from the route or trusted request header;
2. the organization ID persisted in the authenticated session;
3. the user's oldest current membership as the initial default.

Every explicit or persisted selector is resolved through `Current.user.memberships`. A foreign, removed or stale selection raises `ActiveRecord::RecordNotFound`, clears the persisted selector and does not fall back silently to another tenant.

After validation, the request receives:

- `Current.organization`;
- `Current.membership`;
- tenant locale and time zone;
- request and correlation identifiers.

`ActiveSupport::CurrentAttributes` resets the context after each request.

## Tenant selection

`PATCH /tenant_selection` accepts an organization ID and resolves it through the authenticated user's memberships before storing it in the session. The endpoint never accepts a free-standing organization as proof of access.

## Service boundaries

Tenant-aware service objects receive an explicit `organization:` argument. They validate actors, recipients and records with `TenantBoundary` before performing side effects.

Tenant-owned queries start from an organization association or an already authorized organization-scoped relation. Global record lookup followed by a tenant comparison is prohibited.

## Background jobs

Jobs operating on tenant-owned records carry both organization identity and record identity. On execution, the job resolves the organization first and then resolves the record through that organization.

Jobs must revalidate membership when the actor or recipient still needs tenant access at execution time. This prevents queued work from surviving membership removal without review.

## Isolation evidence

The Epic 6 baseline includes negative coverage for:

- foreign and stale tenant selection;
- cross-tenant imports and exports;
- cross-tenant notifications and stored files;
- mismatched tenant-owned records;
- unauthorized ownership transfer.

Future tenant-owned modules must add equivalent negative tests before their public contracts are considered complete.

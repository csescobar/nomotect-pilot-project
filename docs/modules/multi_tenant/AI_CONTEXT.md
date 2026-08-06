# Multi-Tenant Platform AI Context

## Purpose

The Multi-Tenant Platform establishes an explicit organization boundary for every tenant-owned request, service, job and persisted record.

## Public contracts

- `Current.organization` and `Current.membership` represent the validated request tenant.
- `TenantBoundary.assert_membership!` validates that an actor or recipient belongs to an organization.
- `TenantBoundary.assert_record!` rejects records whose `organization_id` differs from the explicit tenant.
- `Organizations::OwnershipTransfer` is the only supported ownership-transfer operation.
- `PATCH /tenant_selection` persists an active organization only after resolving it through the signed-in user's memberships.

## Invariants

1. Tenant-owned records are never loaded globally and then authorized after the fact.
2. A tenant lookup starts from `Current.organization` or from an explicit `organization:` argument.
3. Background jobs serialize organization identity together with the tenant-owned record identity.
4. Removed or stale memberships fail closed and invalidate persisted tenant selection.
5. Tenant locale and time zone apply only after membership validation.
6. Ownership transfer is transactional and preserves at least one owner.
7. Instrumentation may include stable organization identifiers but must not include secrets or sensitive payloads.

## Prohibited patterns

- `TenantOwnedModel.find(params[:id])` without an organization scope.
- Trusting an organization ID, slug, header or signed payload without membership validation.
- Jobs that accept only a tenant-owned record ID.
- Services that infer tenant identity from the first associated record.
- Reusing storage keys, idempotency keys, exports or webhook delivery records across organizations.
- Silently falling back to another organization after a persisted membership becomes stale.

## Review boundaries

Changes to authentication, session persistence, membership lifecycle, tenant-owned queries, jobs, files, imports, exports, notifications, webhooks, audit, feature flags or idempotency require a tenant-isolation review.

Every new tenant-owned capability must include at least one negative test proving that a user or record from another organization is rejected.

## Known limitations

- The current tenant selector exposes a controller contract but not yet a reusable visual switcher component.
- Tenant theme settings are persisted as a supported theme value; custom token overrides are outside the Epic 6 baseline.
- Cross-tenant database policies such as PostgreSQL row-level security are not part of the current architecture.

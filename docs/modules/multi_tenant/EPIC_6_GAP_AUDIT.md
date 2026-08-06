# Epic 6 Corrective Gap Audit

## Context

Merged PR #19 delivered only a minimal change to `Current` and did not complete the Multi-Tenant Platform epic. This audit treats Epic 6 as partially delivered and defines the implementation evidence required before the roadmap can mark it complete.

## Existing baseline

The repository already provides:

- organizations, memberships, invitations and organization policies;
- owner, administrator and member roles;
- final-owner protection on membership role changes and deletion;
- organization-scoped customers and the Enterprise Services introduced in Epic 5;
- a request-scoped `Current` object that currently tracks session, request metadata and locale only.

## Confirmed gaps

### 1. Active tenant context and selection

- `Current` has no organization or membership attributes.
- There is no authoritative resolver that validates the selected organization against the signed-in user's current membership.
- There is no safe persistence contract for tenant selection across requests.
- Time zone and locale are not derived from tenant settings and reset consistently.

Required evidence:

- request middleware/controller concern resolves `Current.organization` and `Current.membership` from an authenticated membership;
- invalid, removed or stale memberships fail closed;
- tenant selection can be changed only to an organization the user currently belongs to;
- context resets after every request and background execution.

### 2. Tenant isolation across application boundaries

Organization associations exist, but association alone is not an isolation guarantee. The following boundaries require explicit scoping and tests:

- customer queries, operations, controllers and policies;
- notifications and notification delivery;
- stored files and storage keys;
- imports, exports and generated artifacts;
- domain events and audit records;
- webhook endpoints and deliveries;
- feature-flag resolution;
- idempotency records and background execution.

Required evidence:

- every tenant-owned lookup starts from the active organization or an explicitly passed organization;
- global `find` calls cannot retrieve tenant-owned records without an organization boundary;
- jobs serialize tenant identity and revalidate membership/authorization where actor context is required;
- service objects reject mismatched tenant-owned inputs.

### 3. Tenant-safe Enterprise Services

Epic 5 services must be reviewed individually rather than assumed safe.

Required review targets:

- customer import and export jobs/services;
- notification dispatcher and delivery job;
- stored-file registry and storage adapter;
- webhook publisher and delivery job;
- workflow transitions and domain-event publication;
- feature-flag lookup;
- idempotent execution records;
- audit and observability payloads.

Required evidence:

- organization identity is explicit in service and job contracts;
- mismatched organization arguments raise a domain/security error;
- logs and instrumentation include stable tenant identifiers without leaking sensitive data;
- exports, files, notifications and webhook deliveries cannot cross tenant boundaries.

### 4. Tenant-specific configuration

Missing platform-level organization settings include:

- theme preference or theme token override reference;
- default locale;
- time zone;
- optional tenant feature and permission configuration.

Required evidence:

- validated persisted settings with safe defaults and data backfill;
- request context applies locale and time zone;
- UI uses accessible controls and localized English/Brazilian Portuguese copy;
- invalid or unsupported settings fail validation.

### 5. Permissions and membership lifecycle

Existing roles provide a baseline but do not complete the lifecycle and concurrency requirements.

Required evidence:

- an explicit ownership-transfer operation with confirmation and transaction boundaries;
- final-owner safeguards that remain correct under concurrent updates/deletions;
- stale-membership handling for active requests and queued jobs;
- privilege-escalation tests for member, administrator and owner boundaries;
- tenant selection invalidation after membership removal.

### 6. Tenant-safe identifiers and serialization

Required evidence:

- public/background payloads carry opaque record identifiers plus organization identity;
- deserialization always resolves tenant-owned records through the organization;
- signed payloads cannot be replayed against another organization;
- storage and export identifiers do not expose paths or permit tenant substitution.

### 7. Cross-tenant leakage test suite

The corrective PR must include explicit negative tests proving that one tenant cannot:

- read or modify another tenant's customer;
- retrieve or download another tenant's stored file;
- import into or export from another tenant;
- read another tenant's audit/domain events;
- deliver or inspect another tenant's notifications;
- invoke another tenant's webhook endpoint;
- resolve another tenant's feature-flag override;
- reuse another tenant's idempotency key;
- select an organization after its membership has been removed;
- transfer ownership or change roles without sufficient permission.

### 8. Documentation and traceability

Required evidence before completion:

- Multi-Tenant module AI context describing invariants, contracts and prohibited access patterns;
- architecture documentation for request and job tenant context;
- roadmap checkboxes updated only after implementation and green CI;
- PR summary maps changed files and tests to each remaining Epic 6 capability.

## Completion gate

Epic 6 is complete only when all remaining roadmap capabilities are implemented, the explicit leakage/privilege tests pass, every Epic 5 enterprise service has a tenant-safety contract, and GitHub Actions is green. A context attribute change, documentation-only change, or association-only implementation is not sufficient.
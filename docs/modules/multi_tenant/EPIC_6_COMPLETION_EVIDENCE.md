# Epic 6 Completion Evidence

## Scope

This document reconciles the early organization work in PRs #11 and #12, the incomplete first Epic 6 attempt in PR #19, the corrective implementation in PR #20, and the final evidence-and-selection round in this pull request.

Epic 6 must not be marked complete until the final pull-request head passes the full CI pipeline.

## Capability mapping

### Active tenant context and tenant selection

Implementation evidence:

- `Current.organization` and `Current.membership` request context;
- membership-scoped resolution in `ApplicationController`;
- persisted active organization in the authenticated session;
- `TenantSelectionsController` for explicit switching;
- stale persisted selections are cleared and fail closed.

Test evidence:

- selection of a current membership succeeds;
- selecting a foreign organization returns not found;
- removing the selected membership causes the next request to fail closed.

### Tenant isolation across domain queries

Implementation evidence:

- organization-scoped customer visibility queries and operations from Epic 4;
- `TenantBoundary` membership and record assertions;
- organization-scoped lookup contracts for tenant-owned services.

Test evidence:

- customer isolation coverage from Epic 4;
- mismatched record and service arguments in `enterprise_services_test.rb`;
- tenant-selection negative tests in this round.

### Tenant-specific permissions, themes and localization

Implementation evidence:

- owner, administrator and member roles;
- tenant locale, time-zone and theme settings with validation and safe defaults;
- request localization applies organization settings after membership validation.

Scope note:

- Epic 6 persists supported theme selection. Tenant-specific token overrides remain outside this baseline.

### Tenant-safe jobs, files, exports and audit

Implementation evidence:

- notification jobs serialize organization and notification identity;
- notification execution resolves the notification through the organization;
- imports, exports and stored-file registration validate membership;
- storage keys include opaque organization-scoped identity;
- ownership transfer publishes an organization-scoped domain event;
- instrumentation includes stable organization identifiers.

Test evidence:

- cross-tenant notification, import, export and file assertions in `enterprise_services_test.rb`.

### Cross-tenant leakage tests

Delivered negative evidence includes:

- foreign and stale tenant selection;
- mismatched tenant-owned record assertions;
- foreign imports and exports;
- foreign notification recipients and delivery lookup;
- foreign file registration;
- unauthorized ownership transfer.

Future modules remain responsible for adding equivalent negative coverage for every new tenant-owned public contract.

### Ownership-transfer workflow and confirmation

Implementation evidence:

- `Organizations::OwnershipTransfer` requires an existing owner actor and current target membership;
- the operation locks the organization and relevant memberships;
- the target becomes owner and the previous owner becomes administrator in one transaction;
- a tenant-scoped domain event records the transfer.

The operation is the domain confirmation boundary. A visual confirmation dialog may be added when the ownership-transfer UI is exposed.

## Documentation evidence

- `docs/modules/multi_tenant/AI_CONTEXT.md` defines invariants and prohibited patterns;
- `docs/architecture/multi-tenant-context.md` defines request, session, service and job context;
- `docs/modules/multi_tenant/EPIC_6_GAP_AUDIT.md` retains the original corrective audit;
- this document maps roadmap capabilities to implementation and tests.

## Final gate

Before merging this corrective round:

- run migration freshness checks;
- run RuboCop;
- run Brakeman and dependency auditing;
- run the complete Minitest suite;
- confirm no required CI stage was skipped;
- update `docs/roadmap/roadmap.md` to mark Epic 6 complete only after the final head is green;
- update the README status to identify Epic 7 as the next active implementation epic.

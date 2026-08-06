# Adoption Validation Improvements

Status: **Completed**

This roadmap item tracks the independent adoption validation pilot (Phase 8) in which
an assistant with zero prior institutional knowledge validates that NomoTect can be
adopted to build a fully functional, tenant-safe application under `/application`.

## Outcome

- **Product:** Service Desk Lite under `application/`
- **Platform:** NomoTect `0.9.0` (Application Starter)
- **Pilot execution plan:** [`docs/ai/phase8-pilot-plan.md`](../ai/phase8-pilot-plan.md)
- **Manual adoption evidence:** [`validation/manual-adoption/`](../../validation/manual-adoption/)

## Validation scope

The pilot validated the required capabilities described in
`docs/ai/phase8-pilot-plan.md`:

- Domain operations and tenant isolation policies
- Component-based CRUD pages using NomoTect Design Tokens
- Data Grid Engine integration (JSON and CSV exports)
- Async background jobs with tenant-safe membership checks
- File attachment handling and downloads
- One custom extension registered through the application surfaces
- Real-browser automated system test suite
- Machine-readable readiness and evidence reports

## Definition of done

- [x] Application-owned module under `/application` with roles, grids, routes, locales and views
- [x] Domain operations publishing domain events through `ApplicationOperation`
- [x] Tenant boundary enforced on every cross-tenant lookup and write
- [x] Grid Engine catalog integration with an authorized scope
- [x] Custom role registration with explicit permissions
- [x] Custom extension package with capability provider
- [x] Idempotent background job for assigned-agent notification
- [x] File attachment flow through `EnterpriseStorage`
- [x] Functional test suite (model, operations, policy, controller, grid, job, SLA)
- [x] Manual adoption evidence under `validation/manual-adoption/`
- [x] `bin/ci` checks pass individually (design tokens, lint, security, tests)

## Known environment blockers (pre-existing)

- `bin/repository-intelligence validate` aborts on 12 platform-owned documentation files
  declared in `config/ai/documentation.yml` that were never committed in the Application
  Starter bootstrap commit. These files are outside the application-adoption boundary
  and predate this work.
- The 4 application system tests and the platform's 8 EJ2 showcase system tests require
  the licensed Syncfusion EJ2 trial assets, which are not committed
  (`bin/extract_syncfusion_assets` needs `syncfusionejs2_trial.zip`).

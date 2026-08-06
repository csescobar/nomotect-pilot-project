# Manual Adoption Validation — Service Desk Lite

This directory contains the evidence for the Phase 8 independent adoption validation:
an assistant with zero prior institutional knowledge adopts NomoTect to build a fully
functional, tenant-safe application under `/application`.

## What was built

Service Desk Lite, an application-owned module under `application/`:

- **Service requests** — CRUD with a strict status transition map (`open → triaged →
  in_progress → resolved → closed`) and per-organization sequential identifiers.
- **Custom roles** — `administrator`, `support_agent`, `requester` registered in
  `application/config/roles.rb` with explicit permissions.
- **Tenant isolation** — every cross-tenant lookup is org-scoped; every write passes
  through `TenantBoundary`; a requester can only see their own requests.
- **Grid Engine** — `service_requests` grid registered in `application/config/grids.rb`
  with JSON and CSV exports.
- **Attachments** — files stored via `EnterpriseStorage` with SHA256 checksums and an
  attachment audit event.
- **Idempotent job** — `NotifyAssignedAgentJob` notifies the assigned agent exactly once.
- **SLA targets** — `ServiceRequests::SlaTarget` resolves deterministic per-priority
  targets through the `nomotect.service-desk-sla` extension capability.
- **Design tokens** — the platform theme was regenerated with the Neo-Brutalist/Earthy
  palette so the application pages render with the adopted look.
- **Demo seed** — `bin/rails demo:seed` provisions two organizations with 80 service
  requests and evidence attachments.

## How to validate

```bash
# Provision demo data (idempotent)
bin/rails demo:seed

# Run the platform CI entrypoint
bin/ci

# Application test suite
bin/rails test application/test
```

### Demo accounts

Password for every account: `NomoTectLocal2026!`

| Organization | Role | Email |
| --- | --- | --- |
| Acme Services | administrator | admin-1@acme-services.example.com |
| Acme Services | support_agent | agent-1@acme-services.example.com |
| Acme Services | requester | requester-1@acme-services.example.com |
| Orion Support | administrator | admin-1@orion-support.example.com |
| Orion Support | support_agent | agent-1@orion-support.example.com |
| Orion Support | requester | requester-1@orion-support.example.com |

## Evidence

- [`evidence.json`](evidence.json) — machine-readable validation report, including the
  honest `undocumented_context_step_count` (11 steps) and baseline comparison.
- [`tmp/validation/mcp-setup-certification.json`](../../tmp/validation/mcp-setup-certification.json) —
  the MCP bootstrap local handshake.
- [`tmp/validation/service-desk-performance.json`](../../tmp/validation/service-desk-performance.json) —
  benchmark measurements for grid, create and SLA resolution.
- [`tmp/validation/baseline-test-report.txt`](../../tmp/validation/baseline-test-report.txt) —
  the pre-change baseline test report.

## Test summary

| Suite | Runs | Status |
| --- | --- | --- |
| Model | 13 | pass |
| Operations | 7 | pass |
| SLA target | 4 | pass |
| Policy | 5 | pass |
| Job idempotency | 4 | pass |
| Grid registration | 5 | pass |
| Controller | 13 | pass |
| System (Cuprite) | 4 | pass |

All 51 tests pass. The system tests exercise the full
requester-creates → admin-transitions → admin-assigns flow and the requester
scoping rule in the grid. The Syncfusion EJ2 trial assets are committed under
`vendor/` (extracted via `bin/extract_syncfusion_assets`); extracting them also
resolved the platform's own 8 EJ2 showcase system tests in the baseline.

## Known limitations

- The Syncfusion EJ2 assets are licensed trial assets committed under `vendor/`;
  the full licensed package is not included.
- The SLA extension is committed with `enabled: false` because the platform's
  `application_extension_sample_test` asserts that the default configuration has no
  enabled extensions and `ApplicationLayer::Certification` rejects any enabled
  extension. The capability is proven through the documented in-memory enablement
  consumer path.
- The platform's 6 pre-existing test failures and 22 errors are unrelated to this work.

## Findings

### FIND-2026-001 — Application pages are unreachable from the platform navigation

**Severity:** medium

Service Desk Lite routes (e.g. `/organizations/63/service_requests`) are registered
only in `application/config/routes/application.rb` and render correctly at their
direct URL. The platform navigation (Dashboard, Organizations, Grid Engine, Component
Showcase, EJ2 Components) is hardcoded in the protected layout
(`app/views/layouts/application.html.erb`) and the organization show page links only to
the platform Customers feature. There is no documented application-owned extension
point to contribute navigation items or organization-scoped links, so an application
user cannot discover application pages without typing the URL.

**Recommendation:** implement a navigation extension point (e.g. application-registered
nav items or organization-scoped links) or disable the platform demo navigation for
application-owned pages. This is a platform contract change beyond the
application-adoption boundary and is tracked as follow-up work.

**Status:** open

# Epic 7 Threat Model

## Assets

Authentication sessions, tenant membership, personal data, privacy requests, audit evidence, uploaded files, exports, webhook secrets, encryption keys, CI artifacts and release metadata.

## Trust boundaries

1. Browser to Rails request boundary.
2. Authenticated user to active tenant boundary.
3. Rails process to PostgreSQL, cache, job queue and file storage.
4. Application repository to GitHub Actions and generated artifacts.
5. Outbound integration and webhook boundary.

## Principal threats and controls

| Threat | Control | Regression evidence |
|---|---|---|
| Cross-tenant data access / IDOR | `Current.organization`, `TenantBoundary`, tenant-scoped privacy queries | negative tenant tests |
| CSRF and request forgery | Rails forgery protection, same-site cookies, CSP form restrictions | integration tests retain CSRF |
| Script injection | restrictive nonce CSP, no wildcard or unsafe-inline sources | header tests |
| Clickjacking and MIME confusion | frame denial, frame ancestors, nosniff | response-header tests |
| Abuse and resource exhaustion | hashed scoped throttles, Retry-After, instrumentation | threshold and separation tests |
| Sensitive-data disclosure | parameter filtering, secret registry, opaque identifiers | redaction tests |
| Privacy export leakage | requester and organization boundary plus deterministic checksum | export isolation tests |
| Destructive retention across tenants | allowlisted models and organization predicates | retention tests |
| Dependency compromise | bundler audit, Brakeman, deterministic SBOM and checksums | CI artifacts |
| Replay of background payloads | organization identifier serialized with record identifier and re-resolution | job contract tests |

## Module abuse cases

- Authentication: credential stuffing, session fixation, token disclosure.
- Multi-tenancy: stale membership, header spoofing, tenant substitution.
- Files: path traversal, storage-key substitution, cross-tenant download.
- Imports/exports: formula injection, oversized input, export scope bypass.
- Webhooks: SSRF, secret disclosure, replay and signature bypass.
- Privacy: unauthorized export, repeated anonymization, deletion of legally retained evidence.

## Severity and triage

Critical and high findings block merge and release. Medium findings require remediation or an explicit time-bounded risk acceptance. Low findings are tracked with ownership. Suspected credential exposure triggers immediate rotation, access review and evidence preservation.

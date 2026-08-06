# Security and Privacy AI Context

## Purpose

This module defines the platform-wide invariants for privacy workflows, HTTP security, abuse prevention, secret handling, supply-chain evidence and threat-driven regression testing.

## Invariants

- Every privacy record is tenant-owned and every lookup starts from an explicit organization boundary.
- Data exports include only records visible to the authenticated requester in the active tenant.
- Anonymization preserves required audit evidence while removing or replacing direct identifiers.
- Retention jobs act only on allowlisted record types and tenant-scoped relations.
- CSP must remain nonce-based and must not introduce `unsafe-inline` or wildcard origins.
- Throttle identities are hashed before entering cache keys or instrumentation.
- Secrets never appear in logs, serialized payloads, exceptions or instrumentation.
- CI always emits security evidence, including static-analysis output, SBOM and checksum artifacts.

## Prohibited patterns

- Global `find` calls for tenant-owned privacy records.
- Raw email addresses, tokens or IP addresses in throttle keys.
- Disabling CSRF protection to make tests pass.
- Broad CSP sources such as `*`, `unsafe-inline` or `unsafe-eval`.
- Logging credentials, encrypted values, reset tokens or webhook secrets.
- Destructive retention jobs without an allowlist and tenant boundary.
- Marking Epic 7 complete before the final PR-head CI run is green.

## Review evidence

Changes require tests for tenant isolation, authorization, replay or idempotency where relevant, secure headers, redaction, generated security artifacts and failure behavior. Human security review remains mandatory for changes to authentication, encryption, tenant boundaries or deletion behavior.

# Security and Privacy Operations

## Privacy lifecycle

Privacy requests are created for the authenticated user and active organization, queued with both organization and request identifiers, and re-resolved through the tenant boundary. Export results include a SHA-256 digest. Anonymization removes optional processing preferences and replaces direct customer identifiers while retaining the privacy request and existing audit evidence.

Retention policies are tenant-owned, limited to allowlisted record types and executed idempotently against records older than the configured cutoff.

## CSP rollout

The default policy is enforced and nonce-based. Set `CSP_REPORT_ONLY=true` during a controlled rollout to emit report-only headers. Never add wildcard sources, `unsafe-inline` or `unsafe-eval` to resolve a compatibility issue; instead update the component to consume the request nonce or an external asset.

## Throttling

Throttle identities combine the relevant actor and tenant identifiers, are SHA-256 hashed before use, and return `Retry-After` metadata. Block events contain only scope and retry duration. Production deployments must configure a shared cache such as Redis so limits apply across processes.

## Secret classes and ownership

- Runtime signing and encryption: platform operations owner.
- Database and cache credentials: infrastructure owner.
- Webhook and integration secrets: tenant integration owner.
- CI and release credentials: repository administrators.

Secrets belong in encrypted credentials or the deployment secret store, not source control. Required production secrets are validated at startup. Rotation must support an overlap window when an external consumer or encrypted record still depends on the previous key version.

## Rotation procedure

1. Create the replacement secret in the authoritative secret store.
2. Deploy readers that accept the current and previous versions where needed.
3. Switch writers to the new version.
4. Verify application health, signatures and decryptability.
5. Revoke the previous secret and record the rotation evidence.

## Incident response

On suspected disclosure: stop further exposure, rotate the affected secret, invalidate sessions or signatures as applicable, review audit and CI evidence, identify impacted tenants and records, and follow the security disclosure and privacy-notification process. Never paste live secrets into issues, pull requests or chat transcripts.

## Supply-chain verification

CI runs lint, Brakeman, dependency auditing and tests, then generates `tmp/ci/sbom.cdx.json` and its SHA-256 checksum. Release automation must bind these artifacts to the source commit and preserve them with the release evidence.

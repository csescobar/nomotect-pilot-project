# Operational Readiness Architecture

Epic 9 Phase 7 begins with credential-free contracts for complete backup sets
and explicit restore plans. This baseline describes evidence and ordering; it
does not execute provider commands or claim that a restore has been certified.

## Backup set

An operational backup manifest binds one source revision and installation state
to exactly four checksum-protected components:

1. PostgreSQL;
2. persistent files;
3. generated configuration;
4. installation metadata.

Provider references identify operator-controlled storage without embedding
credentials, tokens, private keys or provider secrets. Backup media remains
outside the repository and outside application persistence.

## Restore plan

A restore plan references one backup manifest and declares ordered,
dependency-aware steps. Each step names the component, the intended provider
adapter action and whether operator confirmation is required.

Restore execution is mediated by an explicit provider/component adapter
registry. Before any adapter runs, the safety gate requires a matching manifest,
a `production-like` target, maintenance mode, drained requests and jobs, a
complete component plan and operator confirmation for every protected step.
Each component checksum is verified immediately before execution, and the
ordered operation runs under the installation execution lock.

## Verification boundary

Every restore plan declares verification for:

- database schema;
- installation contract;
- generated artifacts;
- application health.

Certification fails closed when a component, adapter, checksum, dependency or
required verification result is unavailable. The production-like certification
uses temporary component media and target storage; it exercises the same safety,
ordering, checksum and verification services without claiming support for a
specific PostgreSQL or object-storage provider.

Run the focused certification with:

```bash
bundle exec rails test \
  test/services/operational_readiness \
  test/integration/operational_restore_certification_test.rb
```

## Security and privacy

Both contracts reject secret-bearing fields. They contain operational metadata
and storage references only. Providers are responsible for encryption,
retention, access control and deletion of backup media.

## Compatibility

The contracts start at schema version 1. Changes that remove fields, component
kinds or verification requirements require a new schema version and migration
guidance. Existing upgrade backup evidence remains valid for upgrade safety but
does not by itself prove that a complete Phase 7 backup set is restorable.

## Diagnostic and support bundles

Support bundles are generated locally from an explicit registry of structured
collectors. The baseline includes installed platform state and configuration
presence; it does not collect database rows, user uploads, Rails credentials,
complete environment variables or unprocessed log files.

Every collected value passes through the fail-closed diagnostic redactor before
it is written. Redaction covers registered sensitive field names, authorization
headers, credential-bearing connection URLs, private keys, JWTs, common access
tokens and email addresses. Unsupported values or redaction failures abort the
bundle without leaving partial output.

Each report is JSON, size bounded, checksum-bound in the versioned manifest and
written with mode `0600` inside a `0700` output directory. The manifest records
redaction counts without preserving original values and fixes
`automated_upload` to `false`.

Inspect the manifest without writing diagnostic output:

```bash
ruby bin/support-bundle inspect
```

Generate a local bundle directory:

```bash
ruby bin/support-bundle build --output var/support/support-bundle
```

Operators must review the manifest and reports before transferring a bundle.
Upload, telemetry, support consent and remote retention remain outside this
Phase 7 capability.

## Operational health

The operational health snapshot separates process liveness from deeper
readiness evidence. Explicit, isolated providers cover installation, deployment,
jobs, storage and integrations. Each provider is time bounded and returns a
stable code; timeouts and failures never expose raw exception messages.

Required unhealthy dependencies make the aggregate unhealthy. Unknown required
dependencies and any non-healthy optional dependency make it degraded. The
snapshot is available as human-readable or JSON output and is automatically
included as a redacted support-bundle report.

```bash
ruby bin/operational-health inspect
ruby bin/operational-health inspect --format json
```

The baseline does not make external network calls, upload telemetry or treat an
optional integration failure as process liveness failure.

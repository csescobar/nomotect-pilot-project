# Installation Foundation

Epic 9 Phase 1 introduces reusable operational infrastructure for installation, upgrade, recovery and maintenance flows.

## Boundary

The foundation does not provision PostgreSQL, write secrets, generate branding assets or create the platform owner. Those steps remain focused follow-up work.

## Request flow

```text
Request
  |
  v
Installation Gate
  |-- disabled or completed --> normal Rails request
  |-- health endpoint --------> health response
  `-- incomplete -------------> active wizard step
```

Installation mode is explicitly enabled with `INSTALLATION_ENABLED=true`. This preserves existing deployments until supported packaging profiles enable first-run behavior for fresh distributions.

Production installation requests require `INSTALLATION_TOKEN` and `INSTALLATION_TOKEN_ISSUED_AT`. The token is SHA-256 digested before constant-time comparison and expires after 30 minutes by default. Sensitive installation parameters are filtered from Rails logs.

## State machine

```text
not_started -> appearance -> database -> provisioning -> migrations -> platform_owner -> completed
                    |             |             |             |
                    `-------------+-------------+-------------+-> failed
```

The completed state is terminal. Recovery from `failed` must explicitly target the safe resumable step.

## State storage

Before the application database is provisioned, state is written atomically to:

```text
var/installation/state.<environment>.json
```

The file contains schema version, environment, current state, timestamp and non-secret metadata. Environment mismatches and unsupported schemas fail closed.

A later milestone adds the database-backed completion record. Production completion will require both local and database evidence so deleting one marker cannot reopen the installer.

## Concurrency

`Installation::ExecutionLock` uses a non-blocking exclusive filesystem lock. Provisioning operations must run inside this lock and report a conflict rather than execute concurrently.

## Repository Intelligence

The installation-state schema is machine-readable and belongs to the operational-contract graph. Repository Intelligence will validate schema versions, references, secret exclusion, freshness and completion evidence as later Phase 1 milestones are delivered.

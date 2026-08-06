# Installation migration orchestration

The migration step runs only after database provisioning has persisted runtime credentials through the configured secret store.

## Contracts

- The runner uses an isolated Active Record connection and does not replace the current application connection pool.
- Runtime credentials are loaded only for the migration operation and are never written to installation state or progress output.
- Rails migrations are idempotent and may be retried after interruption.
- Completion requires verification of the core user, organization, membership and installation-evidence tables.
- A successful run inserts a database-backed `installation_records` entry with contract version, schema version, environment and status.
- Local installation state advances from `provisioning` through `migrations` to `platform_owner` only after verification succeeds.
- Failed runs return to `provisioning`, retain non-secret metadata and expose a sanitized progress event.

## Recovery

Operators may correct the runtime secret-store values and rerun the migration step. The execution lock prevents concurrent migration attempts. Database migration failures never reopen appearance or database provisioning automatically.

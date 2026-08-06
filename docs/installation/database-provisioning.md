# Database Provisioning Contract

Epic 9 Phase 1 provisions PostgreSQL through a temporary administrative connection that is independent of the application's Active Record connection.

## Inputs

The database wizard accepts host, port, maintenance database, SSL mode, temporary administrative credentials, application database name and application role name.

Administrative credentials are request-scoped secrets. They must not be written to installation state, progress events, runtime configuration, logs or Repository Intelligence artifacts.

Database and role identifiers must begin with a lowercase letter, contain only lowercase letters, digits and underscores, and contain no more than 63 bytes in the supported ASCII baseline.

## Provisioning sequence

1. Validate configuration and identifiers.
2. Acquire the installation execution lock.
3. Open a temporary `PG::Connection` to the maintenance database.
4. Create or reconcile the application login role with a newly generated runtime password.
5. Create the application database or reconcile its owner.
6. Close the administrative connection.
7. Persist only runtime application credentials through the configured secret store.
8. Record non-secret connection metadata and advance installation state to `provisioning`.

The operations are resumable and idempotent. Existing roles and databases are reconciled rather than treated as unconditional failures.

## Secret store

`Installation::SecretStore::EnvFile` is the local baseline adapter. It writes an environment-specific file under `var/installation` atomically with mode `0600`. Container secrets, Rails credentials and operator-managed environment adapters can implement the same `write!` contract later.

## Progress

`Installation::ProgressStore` records bounded structured events. Messages describe lifecycle status without identifiers that are unnecessary for operators and without credentials or connection strings.

## Deferred boundary

This delivery does not switch the running Rails process to the new database, execute migrations, create installation database records, or create the platform owner. Those actions belong to the following focused installation deliveries.

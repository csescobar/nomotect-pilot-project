# Post-Upgrade Verification and History

PR #54 separates execution completion from upgrade completion. An execution is
not considered a completed upgrade until post-upgrade verification succeeds and
an immutable history record is appended.

The verifier:

1. computes a canonical SHA-256 digest of the strict target manifest;
2. rejects a digest already recorded as completed;
3. requires a completed execution for the same manifest and target version;
4. regenerates deterministic design-token artifacts;
5. detects the installed platform state again;
6. verifies the target version, database availability, absence of pending
   migrations, completed installation state, installation/deployment contract
   versions and generated-artifact freshness;
7. runs a database-backed application health check;
8. atomically records source and target versions, manifest digest, completed
   operations and credential-free verification and backup evidence.

History is stored under `var/upgrade/history.json`. The append operation checks
the digest again so concurrent or accidental replay fails closed. Verification
failures do not create a completed history record. Provider credentials,
exception messages and secret values are never retained.

When execution completed but these checks fail, the recovery advisor classifies
the result as `forward_recovery`. Operators repair and reverify the target state
without replaying operations already recorded as completed.

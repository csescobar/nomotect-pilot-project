# Upgrade Recovery and Certification

PR #55 completes the Phase 3 baseline with deterministic, read-only recovery
guidance and production-like certification. Guidance is derived from the target
manifest, persisted execution state, and stable preflight or verification
findings. It never executes recovery operations.

## Failure classifications

- `retryable`: execution was interrupted, or a reversible operation failed
  before any irreversible operation completed. Preserve the state and resume the
  same manifest after correcting the cause.
- `forward_recovery`: an irreversible operation started or completed, or target
  verification failed after execution completed. Repair the target state and
  resume or reverify without replaying completed work.
- `operator_intervention`: compatibility, backup evidence, persisted state, or
  manifest identity needs a human decision before execution can continue.

Each result conforms to
[`upgrade-recovery.schema.json`](../contracts/upgrade-recovery.schema.json) and
contains a stable failure code, a safe summary, ordered operator actions, and
the failed operation identifier when it can be verified.

Generate guidance from an interrupted or failed execution without changing
state:

```bash
bin/upgrade-recovery \
  --manifest config/upgrades/target.json \
  --state var/upgrade/execution.json
```

Use `--format json` for contract-shaped automation output. Compatibility and
backup blockers may also be passed directly to `Upgrades::RecoveryAdvisor` by
the preflight orchestration layer.

## Rollback boundary

The baseline does not automate application, database, configuration, or
persistent-file rollback. An operation's `reversible` declaration informs
classification but does not prove that a complete rollback implementation
exists. Database migrations are treated as a forward-recovery boundary after an
irreversible operation starts.

Operators must keep maintenance mode active, preserve execution and backup
evidence, and follow the generated actions. Restoring a backup remains a
provider-specific operator procedure until Epic 9 Phase 7 certifies backup and
restore adapters.

## Certification

`bin/upgrade-contract-certify` validates schemas and runs the full upgrade
service and integration certification. The end-to-end test uses temporary
operational files while exercising:

1. manifest compatibility and planning;
2. source-bound, current backup evidence;
3. maintenance, request, and job safety gates;
4. interruption after persisted progress and same-manifest resume;
5. post-upgrade artifact, database, contract, and health verification;
6. digest-bound history and replay prevention;
7. incompatible-source and stale-backup rejection.

The simulation does not claim provider restore certification, real traffic
draining, or a universal rollback system.

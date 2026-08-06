# Upgrade Execution Engine

PR #53 introduces a locked, resumable executor. Execution is authorized only
through the PR #52 safety gate. Manifests never contain executable code:
operation identifiers resolve through a repository-owned registry.

Progress is written atomically after every transition. Completed operations are
skipped on resume; failed operations may be retried only through their reviewed,
idempotent handler. A separate file lock prevents concurrent execution.

Recorded failures contain only the exception class. Messages, arguments,
credentials and arbitrary command output are not persisted. Database,
configuration and generated-artifact handlers are registered explicitly by the
application; arbitrary shell execution remains prohibited.

Failed operations also persist the stable `operation_failed` code. Recovery
classification is derived separately by `Upgrades::RecoveryAdvisor`, so the
executor remains focused on safe progress persistence and idempotent resume.

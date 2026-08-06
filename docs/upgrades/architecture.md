# Upgrade Framework Architecture

## Purpose

The upgrade framework converts an approved, versioned upgrade manifest into a deterministic plan before any database, configuration, generated-artifact, or operator action is executed.

This foundation intentionally separates planning from execution. A manifest can be parsed, validated, and rejected without mutating the application, database, installation evidence, or persistent files.

The read-only inspection and preflight interface is documented in
[`inspection-and-preflight.md`](inspection-and-preflight.md). Its observations
conform to `docs/contracts/installed-platform-state.schema.json`.

## Contract sequence

1. Detect the installed platform version and installed contract versions.
2. Load an immutable upgrade manifest.
3. Validate the manifest structure and supported schema version.
4. Confirm that the installed version satisfies the manifest source requirement.
5. Confirm that the target version is newer than the installed version.
6. Evaluate Ruby, Rails, PostgreSQL, and contract compatibility.
7. Produce a deterministic ordered plan.
8. Require backup evidence before execution when the manifest declares it mandatory.
9. Execute operations through the future upgrade wizard and operation registry.
10. Persist credential-free upgrade history and post-upgrade validation evidence.
11. Classify failures and produce read-only recovery guidance with stable codes.

## Manifest rules

Upgrade manifests are strict JSON documents governed by `docs/contracts/upgrade-manifest.schema.json`.

- Unknown properties are rejected.
- The manifest schema version is independent from the application version.
- Source versions use RubyGems requirement syntax.
- Target versions use semantic version syntax.
- Operations are ordered and have unique identifiers.
- Each operation declares its type, reversibility, and prerequisites.
- Compatibility declares runtime requirements and exact versions of repository contracts.
- Backup requirements name the evidence that an executor must verify.
- Deprecations name the replacement and the version in which removal is planned.

## Operation types

- `database`: Active Record or data migrations.
- `configuration`: versioned configuration transformations.
- `generated_artifacts`: deterministic regeneration or validation.
- `operator_action`: an explicit human-controlled prerequisite or handoff.
- `validation`: pre-upgrade or post-upgrade verification.

The foundation does not execute arbitrary shell commands from a manifest. Later slices will map operation identifiers to repository-owned, reviewed operation implementations.

## Compatibility policy

Compatibility is fail-closed:

- An installed application outside the source requirement is rejected.
- A target that is not newer than the installed version is rejected.
- A supplied runtime version outside its declared requirement is rejected.
- A supplied contract version that differs from the manifest requirement is rejected.
- Missing runtime or contract observations are preflight blockers. Execution must not begin until required observations are available.

Contract schema changes follow additive evolution within a supported version. Breaking changes require a new contract version, an explicit migration operation, compatibility documentation, and a deprecation path where applicable.

## Backup and recovery boundary

A manifest may require backup evidence, but this foundation does not claim that a backup exists or is restorable. Later execution slices must verify provider-specific evidence before the first mutating operation.

Database rollback is not assumed. Every manifest must distinguish reversible operations from operations that require forward recovery. Upgrade history supports a `recovery_required` terminal state for this boundary.

Recovery guidance conforms to `docs/contracts/upgrade-recovery.schema.json`.
It may recommend retry, forward recovery, or operator intervention, but it never
mutates execution state or claims that a reversible declaration provides an
automated rollback implementation.

## Security boundary

Upgrade manifests and history must never contain passwords, access tokens, database URLs with credentials, private keys, or secret-store values. Evidence is limited to identifiers, checksums, timestamps, versions, statuses, and provider-generated references that are safe to retain.

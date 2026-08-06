# NomoTect Operator Handbook

This handbook is the supported entry point for administering a community
installation. It connects the phase-specific guides into one operator workflow.
Run commands from the repository root, preserve generated evidence, and never
place credentials in manifests, logs, support bundles or change fragments.

## Responsibility model

- **Platform administrator:** manages global administrators, organizations,
  appearance, locales and supported extensions.
- **Installation operator:** protects the bootstrap token, supplies secrets only
  to request-scoped setup steps and confirms terminal installation evidence.
- **Deployment operator:** owns infrastructure, runtime secrets, persistent
  storage, health checks and replacement procedures.
- **Release operator:** follows release and distribution certification without
  bypassing immutable publication or provenance controls.
- **Recovery operator:** declares recovery objectives, approves destructive
  transitions and records drill evidence.

Keep duties separated where practical. Every operator action must be attributable
through deployment, release, upgrade or recovery evidence rather than embedded
credentials.

## Administrator guide

Start with [platform concepts](../../README.md), then use the
[installation architecture](../installation/architecture.md) to understand the
global platform administrator and organization owner boundaries. Administrators
must keep global authority separate from tenant membership, review enabled
extensions, and confirm that optional commercial providers never gate community
capabilities.

For diagnostic assistance, create only a
[redacted support bundle](../operations/support-bundles.md). Support identifiers,
telemetry and diagnostic sharing are separate opt-in decisions; none authorizes
automatic upload.

## Installation guide

1. Review the [installation architecture](../installation/architecture.md) and bootstrap-token
   boundary before exposing the installer.
2. Supply database and secret-store credentials only to the active request.
3. Complete provisioning, migrations, initial administrator and organization
   creation.
4. Verify local and database-backed completion evidence.
5. Confirm the installer is permanently closed before accepting normal traffic.

A failed step must be retried through the resumable wizard. Do not edit persisted
installation state to skip a transition.

## Deployment guide

Select and certify one documented profile:

- [Private VPS](../deployment/private-vps.md)
- [Kamal](../deployment/kamal.md)
- [Render](../deployment/render.md)

Before traffic is enabled, verify runtime secrets, database connectivity,
persistent uploads, job execution and health signals. Container replacement must
preserve external state. Treat a degraded dependency as an explicit health
finding, not as permission to bypass readiness gates.

## Upgrade guide

Follow the [upgrade architecture](../upgrades/architecture.md), run compatibility
preflight, capture backup evidence, enter maintenance mode and execute only
registered operations. Preserve the immutable upgrade history and complete
[post-upgrade verification](../upgrades/post-upgrade-verification.md).

If verification fails, use the read-only
[recovery advisor](../upgrades/recovery-and-certification.md). Database rollback
is never assumed; irreversible work requires forward recovery or explicit
operator intervention.

## Recovery guide

Define installation-specific RTO and RPO in the
[disaster-recovery policy](../operations/disaster-recovery.md). A recovery event
requires:

1. declared scenario and approved recovery plan;
2. verified backup manifest and component checksums;
3. maintenance mode and drained work;
4. restore execution in the documented order;
5. application, job, storage and integration verification;
6. human approval before return to service;
7. recorded actual RTO/RPO and updated runbook evidence.

Use [resilience certification](../operations/resilience-certification.md) for
production-like drills. Never treat a successful backup as proof of restore.

## Extension guide

Use the [extension lifecycle guide](../extensions/lifecycle-guide.md) for
discovery, compatibility preflight, trusted loading, readiness and upgrades.
Extensions are trusted in-process code and require explicit operator approval.
Unknown contracts, incompatible versions and failing providers remain
fail-closed. Removing an extension must not corrupt community-owned state.

## Release and distribution operations

The [release process](../governance/release-process.md) defines change fragments,
generated documents and certification. The
[distribution operations guide](../distribution/operations.md) covers controlled
GitHub Release and GHCR publication. Never republish immutable artifacts or retry
a partially published release blindly; preserve evidence and follow forward
recovery.

## Routine operator checklist

- Review installation, deployment, jobs, storage and integration health.
- Verify backup freshness and schedule restore drills.
- Review pending upgrades, extension compatibility and deprecations.
- Confirm telemetry and support consent still match current policy.
- Generate redacted diagnostics before escalation.
- Record incidents, actual recovery objectives and follow-up actions.
- Keep this handbook and every linked contract in the same reviewed change.

## Escalation evidence

Provide stable finding codes, timestamps, version and deployment identifiers,
redacted support-bundle checksums, relevant certification reports and the
operator-approved consent record. Never attach raw secrets, tenant content,
database dumps or unredacted logs.

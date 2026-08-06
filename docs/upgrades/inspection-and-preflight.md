# Upgrade Inspection and Preflight

## Purpose

Upgrade inspection answers what is installed and what the target manifest expects. Preflight additionally evaluates whether the installation is ready for that target. Both commands are read-only: they do not run migrations, regenerate artifacts, enable maintenance mode, create backup evidence or persist upgrade history.

## Commands

Provide the target manifest and the installed platform version:

```bash
PLATFORM_VERSION=0.4.0 bin/upgrade inspect \
  --manifest path/to/upgrade-manifest.json

PLATFORM_VERSION=0.4.0 bin/upgrade preflight \
  --manifest path/to/upgrade-manifest.json
```

Use `--format json` for automation. Human-readable output is the default.

`inspect` returns the detected state even when blockers exist. `preflight` exits with status `2` when blockers exist and `0` when the upgrade can proceed to later safety gates. Warnings and required operator actions do not change that exit status, but operators must review them before a future execution command is used.

## Detected state

The versioned `installed-platform-state` contract includes:

- installed platform, Ruby, Rails and PostgreSQL versions;
- installation and optional deployment contract versions;
- current database schema and pending source migrations;
- generated design-token artifact freshness;
- structured enabled-extension versions, contracts, capabilities and component
  summaries;
- pending extension migrations and extension compatibility findings;
- supported repository contract versions.

The detector reads the database migration catalog, installation state and generated files. It does not write to them. The canonical root `VERSION` file supplies the source version by default. Packaged environments may override the observation with `PLATFORM_VERSION`, `SOURCE_VERSION` or `OCI_IMAGE_VERSION`.

Optional `DEPLOYMENT_CONTRACT_VERSION` and `DEPLOYMENT_PROFILE` observations are
included when present. Extensions are discovered from the canonical
`config/extensions.yml` configuration and installed Bundler specifications.
Missing observations required by a target manifest are blockers.

## Readiness and failure codes

Preflight is fail-closed. Stable baseline codes include:

- `manifest_invalid`;
- `source_version_unavailable`;
- `installation_incomplete`;
- `database_unavailable`;
- `pending_source_migrations`;
- `extension_state_incompatible`;
- `pending_extension_migrations`;
- `runtime_version_unavailable`;
- `contract_state_unavailable`;
- `compatibility_failed`;
- `generated_artifacts_stale`;
- `contract_deprecated`;
- `backup_evidence_required`;
- `operator_action_required`.

Reports contain only versions, statuses, schema identifiers, migration names and operator guidance. Passwords, tokens, database URLs and secret-store values are outside the installed-state and report contracts.

## Current boundary

Preflight confirms compatibility and identifies required work; it does not verify backup evidence yet. Backup evidence and maintenance controls belong to PR #52. Execution remains unavailable until PR #53 introduces a locked, resumable state-changing engine.

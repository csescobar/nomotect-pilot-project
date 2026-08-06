# Extension Lifecycle Guide

This guide connects extension authoring, installation, deployment, upgrade and
recovery into one supported lifecycle. Extensions are trusted in-process Ruby
packages; they are not downloaded, installed, reloaded or isolated by the
platform at runtime.

## Author

1. Package the extension separately from the community repository.
2. Add a versioned `platform-extension.yml` that declares identity, platform
   compatibility, capabilities, dependencies and every component boundary.
3. Keep the gem entrypoint free of global side effects and register only
   through `Extensions.register`.
4. Declare every capability and hook before registering it.
5. Validate configuration, migration and documentation paths inside the real
   package root.

See [Extension Authoring](authoring.md) for the public registration API and
[Extension Architecture](architecture.md) for the trust and repository
boundaries.

## Install

1. Add the extension gem to the deployment bundle with automatic Bundler
   loading disabled.
2. Build and deploy an artifact that contains the exact gem version.
3. Add an external platform package declaration to `config/extensions.yml`,
   or an application-owned declaration to `application/config/extensions.yml`.
4. Run `bin/extensions inspect` and then `bin/extensions preflight`.
5. Do not start normal traffic unless preflight is ready.

The platform does not install gems and does not fetch extension code. A package
listed in configuration must already be present in the immutable deployment
artifact.

## Deploy

- Use the same bundle, extension configuration and generated artifacts for
  application and job processes.
- Replace every process after adding, removing, repairing or upgrading an
  extension.
- Keep readiness traffic-gated until `/health` reports `ready` or an explicitly
  accepted `degraded` state.
- Treat liveness and readiness separately: a running process may still be
  unable to serve normal traffic.
- Never place credentials in the extension manifest, extension configuration
  declaration, installed-state evidence or health output.

## Upgrade

1. Capture the required database and persistent-file backup evidence.
2. Activate maintenance controls.
3. Run platform upgrade inspection and preflight.
4. Resolve `extension_state_incompatible` findings before execution.
5. Apply pending namespaced extension migrations only through the controlled
   upgrade operation.
6. Deploy the target bundle and configuration together.
7. Replace all application and job processes and verify readiness.

Installed extension state records versions, contracts, components, capability
metadata and pending migrations without loading entrypoints. See
[Component Isolation and Upgrade State](components-and-upgrades.md).

## Recover

For a preflight blocker, repair the immutable package set, configuration or
version graph and start replacement processes. For `restart_required`, preserve
the stable failure evidence, stop routing normal traffic and replace the
process; never retry loading inside the affected Ruby process.

Rollback is limited by the platform upgrade manifest and by whether database or
extension operations are reversible. When rollback is not explicitly
supported, follow forward-recovery guidance, restore from verified evidence if
required, and re-run preflight before returning traffic.

See [Extension Operations](operations.md) for runtime states and the operator
response checklist.

## Security boundary

Real-path validation prevents component declarations from escaping the package
root. It does not sandbox extension Ruby code. Operators must review,
license-pin and supply-chain-verify every extension as trusted application
code. The community core remains functional with an empty extension set.

# Extension Operations

The extension lifecycle runs once during process initialization. It discovers
configured packages, evaluates the complete dependency and capability graph,
removes only safely scoped incompatible optional extensions, and loads the
remaining ready plan in dependency order.

## Runtime statuses

- `ready`: every enabled extension loaded and normal traffic is allowed;
- `degraded`: one or more optional extensions were skipped before code
  execution and normal traffic is allowed;
- `blocked`: a required or graph-wide preflight finding prevents loading and
  normal traffic is denied;
- `restart_required`: initialization or entrypoint execution failed and the
  process must be replaced;
- `not_started`: lifecycle initialization has not completed and normal traffic
  is denied.

The application health endpoint reports extension readiness, loaded and
skipped identifiers, stable blocker and warning codes, and whether a restart is
required. It never reports exception messages, configuration values, secrets
or package paths. The Rails liveness endpoint remains independent so an
orchestrator can distinguish a running process from an application that is not
ready to serve traffic.

## Required and optional behavior

A finding can be skipped only when all blockers are explicitly scoped to
optional extensions. Graph-wide findings, missing identifiers, required
extension findings and required dependencies on an optional extension remain
blocking.

Optional skipping occurs before entrypoint execution. If any entrypoint begins
execution and fails, the registry may contain partial trusted-code side effects
even though registration itself is atomic. The lifecycle therefore requires a
process restart and does not attempt to continue with other extensions.

Installing, removing, upgrading or repairing an extension requires restarting
every application and job process. Hot loading, hot unloading and in-process
retry are unsupported.

## Operator response

For `blocked` or `restart_required`:

1. inspect the health response or run `bin/extensions preflight`;
2. correct the package, version, dependency, capability or component finding;
3. replace the affected application and job processes;
4. confirm health reports `ready` or an accepted `degraded` state before
   restoring normal traffic.

Do not bypass the request gate or edit persisted readiness evidence. The
lifecycle derives its state again from canonical configuration and installed
packages on the next process start.

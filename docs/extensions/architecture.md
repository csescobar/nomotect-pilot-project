# Enterprise Extension Platform Architecture

Epic 9 Phase 5 establishes a provider-neutral contract for trusted,
independently versioned Ruby packages. The platform supplies the integration
surface; proprietary capabilities remain outside the Apache-licensed
community repository.

## Package boundary

Supported external extensions are Bundler-installed gems declared with
`require: false`. Application-owned packages may instead live under the fixed
`application/extensions/<package>` boundary. Each package exposes a
`platform-extension.yml` file that can be read without executing the extension
entrypoint.

The community repository owns:

- versioned manifest and configuration schemas;
- compatibility, dependency and capability validation;
- explicit registration hooks;
- lifecycle, readiness and upgrade integration;
- author, operator and certification tooling.

An external extension repository owns its implementation, tests, migrations,
assets and separately licensed documentation. The community core must not
reference extension implementation constants or private repository locations.

## Contract boundary

The extension manifest declares identity, semantic version, supported platform
requirement, extension contract version, capabilities, dependencies and all
component surfaces. Unknown fields are rejected. Component paths must remain
relative to the package root.

The extension configuration identifies packages that an installation enables
and whether each one is operationally required. Configuration is
credential-free; extension secrets continue to use the platform secret-store
boundary.

The runtime combines the platform-owned `config/extensions.yml` declarations
with product-owned `application/config/extensions.yml`. Duplicate ids or
package names across those files fail closed. Configured local package names
resolve only below `application/extensions`; arbitrary paths and path traversal
are not accepted.

## Security boundary

Extensions execute inside the Rails process and therefore have the privileges
of the application. They are trusted code, not sandboxed plugins. The platform
prevents code execution before compatibility validation, but it cannot contain
a malicious package after loading.

No extension installation, download, license verification, entitlement,
signature verification or package publication is part of this phase.

Compatibility is evaluated across the complete enabled graph before loading.
See [Extension Inspection and Preflight](inspection.md) for package discovery,
stable blocker codes and the read-only operator commands.

Compatible entrypoints use the explicit registration SDK described in
[Extension Authoring](authoring.md). Registration is atomic and the registry is
sealed after dependency-ordered loading.

Filesystem-backed components are resolved with real paths after compatibility
preflight. Configuration schemas and documentation must be files, migration
paths must be directories, and every resolved resource must remain below the
package root even when a package contains symbolic links. Route, asset and
migration namespaces remain extension-owned and explicit. See
[Component Isolation and Upgrade State](components-and-upgrades.md).

The runtime lifecycle starts once per process after Rails initialization. It
loads only a ready plan, publishes bounded readiness state and never retries or
unloads extension code in place. Required-extension failures keep normal
traffic closed. Optional incompatibilities may be removed before any entrypoint
executes when every related finding is scoped to that optional extension.
Operational behavior is documented in [Extension Operations](operations.md).

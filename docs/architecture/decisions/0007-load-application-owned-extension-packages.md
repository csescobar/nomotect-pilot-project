# ADR 0007 — Load Application-Owned Extension Packages

## Status

Accepted

## Context

The extension platform supports installed gems, but product teams need to build and test private extensions inside the `/application` ownership boundary before extracting them into separate packages. Requiring edits to `config/extensions.yml` or relying on arbitrary filesystem paths would violate the application boundary established by ADR 0005.

## Decision

Add `application/config/extensions.yml` as a fixed product-owned configuration source and `application/extensions/<package>` as the only local package root. Runtime, inspection and upgrade state combine platform and application declarations before validation. Duplicate extension ids or package names fail closed.

Installed Bundler packages remain the first resolution source. Otherwise, a configured package may resolve to a real directory immediately below `application/extensions`. Its manifest is inspected before execution, and its entrypoint must resolve to a real Ruby file below the package `lib` directory.

Track a disabled sample extension that is continuously tested through fallback, discovery, compatibility, loading and explicit capability registration.

## Alternatives considered

### Require every application extension to be a published gem

Rejected because it adds packaging overhead during private product development and does not solve the product-owned configuration boundary.

### Accept absolute or relative package paths in configuration

Rejected because arbitrary paths expand the trusted execution surface and make starter portability unreliable.

### Scan every directory under `application/extensions`

Rejected because installed behavior must be explicit. Only configured package identifiers are resolved.

## Consequences

- Private products can develop extensions without modifying protected platform files.
- Local and gem packages share the same manifest, compatibility and registration contracts.
- The sample is disabled by default, preserving extension-free community behavior.
- Changes to enabled extensions still require process replacement; hot reload and hot unload remain unsupported.

## Security and privacy

Configuration accepts identifiers rather than paths. Real-path checks prevent package and entrypoint symbolic links from escaping fixed roots. Extensions remain trusted in-process code, not sandboxes. The sample performs no persistence, network access or personal-data processing.

## Migration and rollback

No database migration is required. Existing `config/extensions.yml` installations continue to work. Rollback removes the application configuration source, local resolver and sample together; deployments using application-owned extensions must package them as gems or disable them first.

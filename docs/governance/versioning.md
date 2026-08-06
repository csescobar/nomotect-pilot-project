# Versioning Policy

The platform follows Semantic Versioning for released public contracts.

## Version format

```text
MAJOR.MINOR.PATCH
```

- Increment **MAJOR** for incompatible changes to supported public contracts.
- Increment **MINOR** for backward-compatible functionality.
- Increment **PATCH** for backward-compatible fixes and security updates.

## Public contracts

Versioning applies to documented extension points, including:

- Component APIs and design token names.
- Grid query protocol, type registry and adapter contracts.
- Configuration file schemas.
- Generator output expectations.
- Audit event and integration payload contracts.
- Supported environment and dependency versions.

Internal implementation details are not automatically public contracts, but maintainers should avoid needless churn.

## Deprecation

A backward-compatible deprecation should:

1. Identify the replacement.
2. Produce a clear development warning when practical.
3. Include migration guidance.
4. Remain available for at least one documented compatibility window.
5. Be removed only in a major release unless continued support creates a security risk.

## Pre-1.0 policy

Before version 1.0, minor versions may contain contract changes. Such changes must still be documented clearly, include migration instructions and avoid unnecessary breakage.

## Supported versions

The project will publish a support matrix after the first stable release. The intended model is:

- Current major/minor: features, bug fixes and security fixes.
- Previous supported minor: critical bug and security fixes for a limited window.
- Unsupported versions: no guaranteed fixes.

## Database and data compatibility

Schema and data changes must state their compatibility requirements separately from package versioning. A nominally backward-compatible code release must not silently make rollback unsafe.

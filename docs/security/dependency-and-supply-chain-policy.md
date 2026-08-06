# Dependency and Supply-Chain Policy

## Principles

- Prefer Rails, Ruby standard library and established open-source components.
- Add a dependency only when its value exceeds its maintenance, security and upgrade cost.
- Pin resolved versions through lockfiles and review transitive changes.
- Avoid unmaintained packages and unnecessary overlapping libraries.
- Run vulnerability, license and integrity checks in CI.
- Generate an SBOM for releases once executable artifacts exist.
- Keep build and release processes reproducible and traceable.
- Never commit secrets, production credentials or private keys.

## Dependency proposal

A new foundational dependency must document purpose, license, maintainership, alternatives, security history, replacement strategy and expected runtime impact.

## Updates

Security updates receive priority. Routine updates should be small, tested and reversible. Major framework upgrades require compatibility notes and an ADR when they alter platform contracts.

## Generated artifacts

Generated code and downloaded assets must record their origin and regeneration process. Vendored code retains upstream notices and license obligations.
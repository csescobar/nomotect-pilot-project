# ADR 0002 — Use a Modular Monolith

## Status

Accepted

## Decision

Begin with a modular monolith and explicit domain boundaries.

## Rationale

This provides transactional consistency, operational simplicity and lower cognitive load while preserving a path to later extraction.

## Guardrails

- Namespaces represent domains.
- Cross-domain access uses public operations or events.
- Direct access to another domain's tables is prohibited unless explicitly documented.

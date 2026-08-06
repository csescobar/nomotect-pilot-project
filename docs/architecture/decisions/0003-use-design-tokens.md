# ADR 0003 — Use Design Tokens and CSS Variables

## Status

Accepted

## Decision

Store theme values in a structured JSON source and compile them into CSS custom properties.

## Consequences

- Light and dark themes share a stable semantic token model.
- Components never depend directly on palette values.
- Applications can replace branding without rewriting components.

# ADR 0001 — Use Rails and Hotwire

## Status

Accepted

## Context

The platform requires high productivity for business workflows, server-rendered HTML, progressive enhancement and strong conventions.

## Decision

Use Ruby on Rails with Turbo and Stimulus as the primary application and presentation stack.

## Consequences

- Rails conventions reduce setup and improve onboarding.
- Turbo supports partial navigation and server-rendered interactions.
- Stimulus handles local browser behavior.
- Domain logic must remain independent of Hotwire.

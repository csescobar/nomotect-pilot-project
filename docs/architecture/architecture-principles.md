# Architecture Principles

## Purpose

Provide concise rules used during design and review.

## Principles

1. **Model business language directly.** Prefer expressive operations and value objects over generic record mutation.
2. **Keep boundaries explicit.** Modules expose contracts and hide internal implementation.
3. **Prefer composition.** Inheritance is reserved for stable substitutable behavior.
4. **Make invalid states difficult to represent.** Validate at input, domain and database boundaries.
5. **Separate reads from state changes.** Queries do not perform side effects.
6. **Treat frameworks as adapters.** Domain behavior remains executable without Turbo or HTTP.
7. **Secure defaults over optional hardening.** Authorization, tenant scope and safe logging are mandatory paths.
8. **Design for observability.** Important operations expose structured events, metrics and traces.
9. **Optimize for change.** Avoid speculative abstraction while preserving proven extension points.
10. **Document for humans and agents.** Significant modules and decisions must be discoverable in the repository.

## Review questions

- Where is the business invariant enforced?
- What is the module boundary?
- Which data and permissions are involved?
- Can the behavior be tested without presentation technology?
- What evidence proves security, accessibility and operational readiness?
- Does the change update its contract and documentation?
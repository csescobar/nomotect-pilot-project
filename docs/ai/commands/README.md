# Agent Command Playbooks

This directory will contain vendor-neutral, step-by-step playbooks for recurring platform changes. They are instructions, not executable prompts tied to one AI product.

## Planned playbooks

- `create-module.md`
- `create-component.md`
- `create-grid.md`
- `create-crud.md`
- `create-operation.md`
- `create-domain-event.md`
- `add-permission.md`
- `add-translation.md`
- `add-audit-event.md`
- `review-security-impact.md`
- `review-accessibility.md`

## Required playbook structure

Each playbook must define:

1. Preconditions
2. Files to inspect
3. Files normally changed
4. Ordered implementation steps
5. Architectural constraints
6. Security and privacy checks
7. Required tests
8. Documentation updates
9. Completion report
10. Common failure modes

## Principle

A playbook must guide a contributor toward the supported extension points. It must not encourage broad code generation without inspection or verification.

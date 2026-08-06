# Contribution Model

## Principles

Contributions are evaluated on correctness, maintainability, security, privacy, accessibility and alignment with the platform architecture.

## Change workflow

1. Discuss substantial capabilities through an issue or proposal.
2. Record significant architectural decisions in an ADR.
3. Create a focused branch from `main`.
4. Submit changes through a pull request.
5. Complete automated checks and address review conversations.
6. Merge only after branch rules and required approvals are satisfied.

Direct commits to `main` are not part of the normal workflow.

## Pull request expectations

A pull request should explain:

- The problem and intended outcome.
- Architectural and module impact.
- Security and privacy impact.
- Internationalization and accessibility impact.
- Database, migration and rollback implications.
- Tests and validation performed.
- Whether AI materially assisted the contribution and any remaining uncertainty.

## Review model

Reviewers evaluate both behavior and long-term platform impact. Approval means the reviewer considers the contribution suitable for maintenance, not merely functional in the demonstrated path.

Sensitive areas may require specialized review, including:

- Authentication and session management.
- Authorization and tenant isolation.
- Cryptography and secrets.
- Grid query execution and exports.
- File upload and external integrations.
- Audit, privacy and retention behavior.

## Merge policy

The preferred merge strategy is squash merge to keep the primary history focused on completed changes. Pull request titles should therefore be suitable as final commit subjects.

## Maintainer responsibilities

Maintainers should:

- Apply standards consistently.
- Explain rejected changes constructively.
- Avoid undocumented exceptions.
- Prioritize security and dependency maintenance.
- Preserve a welcoming and technically rigorous contribution environment.
- Identify public contracts before accepting breaking changes.

## AI-assisted contributions

AI-assisted contributions are welcome when they comply with `AI_PRINCIPLES.md`. Prompt output is never accepted as validation evidence by itself.

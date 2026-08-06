# Module Contract Specification

Every major platform module must provide an `AI_CONTEXT.md` file beside its primary implementation or documentation.

## Required sections

1. **Purpose** — the business or technical capability owned by the module.
2. **Responsibilities** — behavior the module must provide.
3. **Non-responsibilities** — behavior that belongs elsewhere.
4. **Public API** — supported entry points, classes, commands, events and configuration.
5. **Invariants** — conditions that must remain true.
6. **Dependencies** — modules this module may call.
7. **Dependents** — known consumers of the module.
8. **Extension points** — supported customization mechanisms.
9. **Protected areas** — files or contracts requiring explicit architectural review.
10. **Security and privacy** — trust boundaries, sensitive data and authorization requirements.
11. **Observability** — logs, metrics, traces and audit events.
12. **Validation** — tests and commands required before completion.
13. **Examples** — canonical usage.
14. **Known limitations** — intentional constraints and unresolved risks.
15. **Related decisions** — ADR references.

## Contract rules

- Contracts describe supported behavior, not every implementation detail.
- Public APIs must not be inferred only from visibility keywords.
- A breaking contract change requires an ADR and versioning assessment.
- Contract changes must be reviewed alongside implementation changes.
- Generated architecture metadata must be derived from or validated against these contracts.

## Initial modules requiring contracts

- Core
- Design System
- Grid
- Identity
- Authorization
- Multi-tenancy
- Audit
- Privacy
- I18n
- Workflows
- Notifications
- Files
- Integrations
- Observability
- Developer Experience

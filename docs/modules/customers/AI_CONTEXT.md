# Customers AI Context

## Purpose

Customers are the reference domain capability for the platform. The module demonstrates how domain models, operations, queries, policies, domain events, grids, audit history, localization, optimistic locking, and tests fit together.

## Owned paths

- `app/models/customer.rb`
- `app/models/domain_event.rb`
- `app/models/concerns/domain_model.rb`
- `app/operations/application_operation.rb`
- `app/operations/customers/**`
- `app/queries/customers/**`
- `app/controllers/customers_controller.rb`
- `app/policies/customer_policy.rb`
- `app/views/customers/**`
- customer migrations, locales, and tests

## Public contracts

1. Writes occur through explicit operation objects.
2. Read scopes occur through explicit query objects.
3. Controllers authorize before invoking operations.
4. Every successful customer write persists a domain event in the same transaction.
5. Customer access is scoped through an organization membership.
6. Owners and administrators may mutate customers; all organization members may read them.
7. `lock_version` is required for updates and stale writes return HTTP 409 with a conflict UI.
8. Domain events are immutable audit evidence; application code does not update or delete them.
9. Visible copy is localized in English and Brazilian Portuguese.
10. Tests cover model invariants, operation atomicity, authorization, tenant isolation, and optimistic-lock conflicts.

## Extension guidance

New reference capabilities should copy the shape, not the customer vocabulary: model invariants, operation transaction, event payload, visibility query, policy, localized UI, conflict handling, and security tests.

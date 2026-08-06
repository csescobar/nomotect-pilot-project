# Customer AI Context

> Generated artifact. Source changes must be followed by regeneration.

## Responsibilities

- model: Customer
- policy: Customer

## Source paths

- `app/models/customer.rb`
- `app/policies/customer_policy.rb`

## Relationships

- `model:Customer` —DOCUMENTED_BY→ `document:Modules::Customers::AiContext`
- `policy:Customer` —DOCUMENTED_BY→ `document:Modules::Customers::AiContext`
- `model:Customer` —TESTED_BY→ `test:Controllers::CustomersController`
- `policy:Customer` —TESTED_BY→ `test:Controllers::CustomersController`
- `model:Customer` —TESTED_BY→ `test:Models::Customer`
- `policy:Customer` —TESTED_BY→ `test:Models::Customer`
- `model:Customer` —TESTED_BY→ `test:Operations::CustomersOperations`
- `policy:Customer` —TESTED_BY→ `test:Operations::CustomersOperations`

## Contract

No dedicated machine-readable contract is currently registered.

## Change checklist

- Run impact analysis for affected nodes.
- Preserve security, privacy and tenant invariants.
- Update required tests and public contracts.
- Regenerate repository intelligence artifacts.

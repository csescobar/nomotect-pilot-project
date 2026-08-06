# Organization AI Context

> Generated artifact. Source changes must be followed by regeneration.

## Responsibilities

- model: Organization
- policy: Organization

## Source paths

- `app/models/organization.rb`
- `app/policies/organization_policy.rb`

## Relationships

- `model:Organization` —DOCUMENTED_BY→ `document:Modules::Organizations::AiContext`
- `policy:Organization` —DOCUMENTED_BY→ `document:Modules::Organizations::AiContext`
- `model:Organization` —TESTED_BY→ `test:Controllers::OrganizationMemberAdministration`
- `policy:Organization` —TESTED_BY→ `test:Controllers::OrganizationMemberAdministration`
- `model:Organization` —TESTED_BY→ `test:Controllers::OrganizationsController`
- `policy:Organization` —TESTED_BY→ `test:Controllers::OrganizationsController`
- `model:Organization` —TESTED_BY→ `test:Models::OrganizationInvitation`
- `policy:Organization` —TESTED_BY→ `test:Models::OrganizationInvitation`
- `model:Organization` —TESTED_BY→ `test:Models::Organization`
- `policy:Organization` —TESTED_BY→ `test:Models::Organization`

## Contract

No dedicated machine-readable contract is currently registered.

## Change checklist

- Run impact analysis for affected nodes.
- Preserve security, privacy and tenant invariants.
- Update required tests and public contracts.
- Regenerate repository intelligence artifacts.

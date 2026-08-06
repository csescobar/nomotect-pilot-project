# Models AI Context

> Generated artifact. Source changes must be followed by regeneration.

## Responsibilities

- test: Models::Customer, Models::GridSavedView, Models::Organization, Models::OrganizationInvitation, Models::PlatformRole, Models::User, Models::UserLocalization

## Source paths

- `test/models/customer_test.rb`
- `test/models/grid_saved_view_test.rb`
- `test/models/organization_invitation_test.rb`
- `test/models/organization_test.rb`
- `test/models/platform_role_test.rb`
- `test/models/user_localization_test.rb`
- `test/models/user_test.rb`

## Relationships

- `model:Customer` —TESTED_BY→ `test:Models::Customer`
- `policy:Customer` —TESTED_BY→ `test:Models::Customer`
- `model:GridSavedView` —TESTED_BY→ `test:Models::GridSavedView`
- `model:Organization` —TESTED_BY→ `test:Models::OrganizationInvitation`
- `model:OrganizationInvitation` —TESTED_BY→ `test:Models::OrganizationInvitation`
- `policy:Organization` —TESTED_BY→ `test:Models::OrganizationInvitation`
- `model:Organization` —TESTED_BY→ `test:Models::Organization`
- `policy:Organization` —TESTED_BY→ `test:Models::Organization`
- `model:PlatformRole` —TESTED_BY→ `test:Models::PlatformRole`
- `model:User` —TESTED_BY→ `test:Models::UserLocalization`
- `document:Design-system::Localization` —TESTED_BY→ `test:Models::UserLocalization`
- `model:User` —TESTED_BY→ `test:Models::User`
- `test:Models::Customer` —TESTED_BY→ `test:Operations::CustomersOperations`

## Contract

No dedicated machine-readable contract is currently registered.

## Change checklist

- Run impact analysis for affected nodes.
- Preserve security, privacy and tenant invariants.
- Update required tests and public contracts.
- Regenerate repository intelligence artifacts.

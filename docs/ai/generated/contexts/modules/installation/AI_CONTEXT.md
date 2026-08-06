# Installation AI Context

> Generated artifact. Source changes must be followed by regeneration.

## Responsibilities

- controller: Installation::Base, Installation::Steps

## Source paths

- `app/controllers/installation/base_controller.rb`
- `app/controllers/installation/steps_controller.rb`

## Relationships

- `controller:Installation::Base` —DOCUMENTED_BY→ `document:Adoption::Phase-4b-grid-ux-baseline`
- `controller:Installation::Base` —DOCUMENTED_BY→ `document:Installation::Database-provisioning`
- `controller:Installation::Base` —DOCUMENTED_BY→ `document:Packaging::Container-baseline`
- `controller:Installation::Base` —DOCUMENTED_BY→ `document:Security::Security-baseline`
- `controller:Installation::Base` —DOCUMENTED_BY→ `document:Validation::Release-baseline`
- `controller:Installation::Steps` —TESTED_BY→ `test:Controllers::Installation::StepsController`
- `controller:Installation::Base` —TESTED_BY→ `test:Services::Epic10::ReleaseBaseline`

## Contract

No dedicated machine-readable contract is currently registered.

## Change checklist

- Run impact analysis for affected nodes.
- Preserve security, privacy and tenant invariants.
- Update required tests and public contracts.
- Regenerate repository intelligence artifacts.

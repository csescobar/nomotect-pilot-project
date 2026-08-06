# Marketing AI Context

> Generated artifact. Source changes must be followed by regeneration.

## Responsibilities

- component: Marketing::ApplicationCategory, Marketing::ArchitectureLayers, Marketing::CallToAction, Marketing::Capability, Marketing::EngineeringFlow, Marketing::Footer, Marketing::Header, Marketing::Hero, Marketing::Lifecycle, Marketing::ProductPreview, Marketing::TechnologyStack
- controller: Marketing

## Source paths

- `app/components/marketing/application_category_component.rb`
- `app/components/marketing/architecture_layers_component.rb`
- `app/components/marketing/call_to_action_component.rb`
- `app/components/marketing/capability_component.rb`
- `app/components/marketing/engineering_flow_component.rb`
- `app/components/marketing/footer_component.rb`
- `app/components/marketing/header_component.rb`
- `app/components/marketing/hero_component.rb`
- `app/components/marketing/lifecycle_component.rb`
- `app/components/marketing/product_preview_component.rb`
- `app/components/marketing/technology_stack_component.rb`
- `app/controllers/marketing_controller.rb`

## Relationships

- `component:Marketing::Lifecycle` —DOCUMENTED_BY→ `document:Extensions::Lifecycle-guide`
- `component:Marketing::Lifecycle` —DOCUMENTED_BY→ `document:Operators::Compatibility-and-lifecycle`
- `controller:Marketing` —TESTED_BY→ `test:Components::MarketingComponents`
- `controller:Marketing` —TESTED_BY→ `test:Controllers::MarketingController`
- `component:Marketing::Lifecycle` —TESTED_BY→ `test:Integration::CompatibilityLifecycleDocumentation`
- `component:Marketing::Header` —TESTED_BY→ `test:Requests::SecurityHeaders`
- `component:Marketing::Lifecycle` —TESTED_BY→ `test:Services::Extensions::Lifecycle`

## Contract

No dedicated machine-readable contract is currently registered.

## Change checklist

- Run impact analysis for affected nodes.
- Preserve security, privacy and tenant invariants.
- Update required tests and public contracts.
- Regenerate repository intelligence artifacts.

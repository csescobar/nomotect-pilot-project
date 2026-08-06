# Components AI Context

> Generated artifact. Source changes must be followed by regeneration.

## Responsibilities

- test: Components::MarketingComponents, Components::Ui::ButtonComponent, Components::Ui::CoreComponents, Components::Ui::DangerZoneComponent, Components::Ui::Forms::FormComponents, Components::Ui::Layout::ApplicationShellComponent, Components::Ui::LocaleSwitcherComponent, Components::Ui::ThemeSwitcherComponent

## Source paths

- `test/components/marketing_components_test.rb`
- `test/components/ui/button_component_test.rb`
- `test/components/ui/core_components_test.rb`
- `test/components/ui/danger_zone_component_test.rb`
- `test/components/ui/forms/form_components_test.rb`
- `test/components/ui/layout/application_shell_component_test.rb`
- `test/components/ui/locale_switcher_component_test.rb`
- `test/components/ui/theme_switcher_component_test.rb`

## Relationships

- `controller:Marketing` —TESTED_BY→ `test:Components::MarketingComponents`
- `component:Ui::Button` —TESTED_BY→ `test:Components::Ui::ButtonComponent`
- `component:Ui::DangerZone` —TESTED_BY→ `test:Components::Ui::DangerZoneComponent`
- `document:Design-system::Forms` —TESTED_BY→ `test:Components::Ui::Forms::FormComponents`
- `component:Application` —TESTED_BY→ `test:Components::Ui::Layout::ApplicationShellComponent`
- `component:Ui::Layout::ApplicationShell` —TESTED_BY→ `test:Components::Ui::Layout::ApplicationShellComponent`
- `controller:Application` —TESTED_BY→ `test:Components::Ui::Layout::ApplicationShellComponent`
- `job:Application` —TESTED_BY→ `test:Components::Ui::Layout::ApplicationShellComponent`
- `policy:Application` —TESTED_BY→ `test:Components::Ui::Layout::ApplicationShellComponent`
- `component:Ui::LocaleSwitcher` —TESTED_BY→ `test:Components::Ui::LocaleSwitcherComponent`
- `component:Ui::ThemeSwitcher` —TESTED_BY→ `test:Components::Ui::ThemeSwitcherComponent`

## Contract

No dedicated machine-readable contract is currently registered.

## Change checklist

- Run impact analysis for affected nodes.
- Preserve security, privacy and tenant invariants.
- Update required tests and public contracts.
- Regenerate repository intelligence artifacts.

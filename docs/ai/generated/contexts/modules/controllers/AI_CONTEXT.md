# Controllers AI Context

> Generated artifact. Source changes must be followed by regeneration.

## Responsibilities

- test: Controllers::ComponentShowcaseController, Controllers::CustomersController, Controllers::DashboardsController, Controllers::Ej2ShowcaseController, Controllers::GridsController, Controllers::GridsControllerSyncfusion, Controllers::HealthController, Controllers::HomeController, Controllers::Installation::StepsController, Controllers::LocalePreferencesController, Controllers::MarketingController, Controllers::OrganizationMemberAdministration, Controllers::OrganizationsController, Controllers::PreferencesController, Controllers::StoredFilesController, Controllers::TenantSelectionsController

## Source paths

- `test/controllers/component_showcase_controller_test.rb`
- `test/controllers/customers_controller_test.rb`
- `test/controllers/dashboards_controller_test.rb`
- `test/controllers/ej2_showcase_controller_test.rb`
- `test/controllers/grids_controller_syncfusion_test.rb`
- `test/controllers/grids_controller_test.rb`
- `test/controllers/health_controller_test.rb`
- `test/controllers/home_controller_test.rb`
- `test/controllers/installation/steps_controller_test.rb`
- `test/controllers/locale_preferences_controller_test.rb`
- `test/controllers/marketing_controller_test.rb`
- `test/controllers/organization_member_administration_test.rb`
- `test/controllers/organizations_controller_test.rb`
- `test/controllers/preferences_controller_test.rb`
- `test/controllers/stored_files_controller_test.rb`
- `test/controllers/tenant_selections_controller_test.rb`

## Relationships

- `controller:ComponentShowcase` —TESTED_BY→ `test:Controllers::ComponentShowcaseController`
- `controller:Customers` —TESTED_BY→ `test:Controllers::CustomersController`
- `model:Customer` —TESTED_BY→ `test:Controllers::CustomersController`
- `policy:Customer` —TESTED_BY→ `test:Controllers::CustomersController`
- `controller:Dashboards` —TESTED_BY→ `test:Controllers::DashboardsController`
- `controller:Ej2Showcase` —TESTED_BY→ `test:Controllers::Ej2ShowcaseController`
- `controller:Grids` —TESTED_BY→ `test:Controllers::GridsControllerSyncfusion`
- `controller:Grids` —TESTED_BY→ `test:Controllers::GridsController`
- `controller:Health` —TESTED_BY→ `test:Controllers::HealthController`
- `controller:Home` —TESTED_BY→ `test:Controllers::HomeController`
- `controller:Installation::Steps` —TESTED_BY→ `test:Controllers::Installation::StepsController`
- `controller:LocalePreferences` —TESTED_BY→ `test:Controllers::LocalePreferencesController`
- `controller:Preferences` —TESTED_BY→ `test:Controllers::LocalePreferencesController`
- `controller:Marketing` —TESTED_BY→ `test:Controllers::MarketingController`
- `model:Organization` —TESTED_BY→ `test:Controllers::OrganizationMemberAdministration`
- `policy:Organization` —TESTED_BY→ `test:Controllers::OrganizationMemberAdministration`
- `controller:Organizations` —TESTED_BY→ `test:Controllers::OrganizationsController`
- `model:Organization` —TESTED_BY→ `test:Controllers::OrganizationsController`
- `policy:Organization` —TESTED_BY→ `test:Controllers::OrganizationsController`
- `controller:Preferences` —TESTED_BY→ `test:Controllers::PreferencesController`
- `controller:StoredFiles` —TESTED_BY→ `test:Controllers::StoredFilesController`
- `model:StoredFile` —TESTED_BY→ `test:Controllers::StoredFilesController`
- `policy:StoredFile` —TESTED_BY→ `test:Controllers::StoredFilesController`
- `controller:TenantSelections` —TESTED_BY→ `test:Controllers::TenantSelectionsController`

## Contract

No dedicated machine-readable contract is currently registered.

## Change checklist

- Run impact analysis for affected nodes.
- Preserve security, privacy and tenant invariants.
- Update required tests and public contracts.
- Regenerate repository intelligence artifacts.

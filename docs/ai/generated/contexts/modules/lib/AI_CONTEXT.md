# Lib AI Context

> Generated artifact. Source changes must be followed by regeneration.

## Responsibilities

- test: Lib::ApplicationRegistrations, Lib::ApplicationStarter, Lib::CleanStarterOnboarding, Lib::ContainerEnvironmentValidator, Lib::DesignTokens::Compiler, Lib::Epic9Certification, Lib::GridEngine::HtmlRenderer, Lib::GridEngine::Query, Lib::GridEngine::SyncfusionAdapter, Lib::GridEngine::Types, Lib::Localization::SupportedLocales, Lib::McpBootstrap, Lib::Platform::Version, Lib::RepositoryIntelligence, Lib::RepositoryIntelligenceAiArtifact, Lib::RepositoryIntelligenceDocumentationGovernance, Lib::RepositoryIntelligenceHealth, Lib::RepositoryIntelligencePlaybookExecutor, Lib::RepositoryIntelligenceStorage

## Source paths

- `test/lib/application_registrations_test.rb`
- `test/lib/application_starter_test.rb`
- `test/lib/clean_starter_onboarding_test.rb`
- `test/lib/container_environment_validator_test.rb`
- `test/lib/design_tokens/compiler_test.rb`
- `test/lib/epic_9_certification_test.rb`
- `test/lib/grid_engine/html_renderer_test.rb`
- `test/lib/grid_engine/query_test.rb`
- `test/lib/grid_engine/syncfusion_adapter_test.rb`
- `test/lib/grid_engine/types_test.rb`
- `test/lib/localization/supported_locales_test.rb`
- `test/lib/mcp_bootstrap_test.rb`
- `test/lib/platform/version_test.rb`
- `test/lib/repository_intelligence_ai_artifact_test.rb`
- `test/lib/repository_intelligence_documentation_governance_test.rb`
- `test/lib/repository_intelligence_health_test.rb`
- `test/lib/repository_intelligence_playbook_executor_test.rb`
- `test/lib/repository_intelligence_storage_test.rb`
- `test/lib/repository_intelligence_test.rb`

## Relationships

- `component:Application` —TESTED_BY→ `test:Lib::ApplicationRegistrations`
- `controller:Application` —TESTED_BY→ `test:Lib::ApplicationRegistrations`
- `job:Application` —TESTED_BY→ `test:Lib::ApplicationRegistrations`
- `policy:Application` —TESTED_BY→ `test:Lib::ApplicationRegistrations`
- `component:Application` —TESTED_BY→ `test:Lib::ApplicationStarter`
- `controller:Application` —TESTED_BY→ `test:Lib::ApplicationStarter`
- `job:Application` —TESTED_BY→ `test:Lib::ApplicationStarter`
- `policy:Application` —TESTED_BY→ `test:Lib::ApplicationStarter`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Lib::Epic9Certification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Lib::Epic9Certification`
- `document:Deployment::Render` —TESTED_BY→ `test:Lib::GridEngine::HtmlRenderer`
- `document:Design-system::Localization` —TESTED_BY→ `test:Lib::Localization::SupportedLocales`
- `controller:Health` —TESTED_BY→ `test:Lib::RepositoryIntelligenceHealth`
- `test:Lib::Platform::Version` —TESTED_BY→ `test:Services::Upgrades::Version`

## Contract

No dedicated machine-readable contract is currently registered.

## Change checklist

- Run impact analysis for affected nodes.
- Preserve security, privacy and tenant invariants.
- Update required tests and public contracts.
- Regenerate repository intelligence artifacts.

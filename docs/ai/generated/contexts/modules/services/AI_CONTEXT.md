# Services AI Context

> Generated artifact. Source changes must be followed by regeneration.

## Responsibilities

- test: Services::ApplicationLayer::Certification, Services::CommercialReadiness::EntitlementResolver, Services::CommercialReadiness::SupportConsent, Services::CommercialReadiness::SupportIdentity, Services::CommercialReadiness::TelemetryPolicy, Services::Distributions::ChannelObserver, Services::Distributions::ChannelState, Services::Distributions::GhcrPromotionPlan, Services::Distributions::GithubReleasePlan, Services::Distributions::Inspector, Services::Distributions::Manifest, Services::Distributions::Verifier, Services::EnterpriseServices, Services::Epic10::AccessibilityCertification, Services::Epic10::AiReadinessCertification, Services::Epic10::ContractValidator, Services::Epic10::DomainServicesJourney, Services::Epic10::FunctionalFrameworkCertification, Services::Epic10::MultitenantExtensionJourney, Services::Epic10::OperationalResilienceCertification, Services::Epic10::PerformanceCompatibilityCertification, Services::Epic10::ProductionDeploymentCertification, Services::Epic10::RcPreparation, Services::Epic10::RcUpgradeCertification, Services::Epic10::RcUpgradeFixture, Services::Epic10::ReleaseBaseline, Services::Epic10::RepresentativeApplication, Services::Epic10::RepresentativeApplicationCertification, Services::Epic10::RepresentativeApplicationJourney, Services::Epic10::SecurityPrivacyIsolationCertification, Services::Extensions::Catalog, Services::Extensions::CompatibilityPlanner, Services::Extensions::ComponentResolver, Services::Extensions::Configuration, Services::Extensions::ExtensionReadinessPlaybook, Services::Extensions::Inspector, Services::Extensions::InstalledState, Services::Extensions::Lifecycle, Services::Extensions::Loader, Services::Extensions::Manifest, Services::Extensions::Registry, Services::Installation::DatabaseConfiguration, Services::Installation::DatabaseProvisioner, Services::Installation::PlatformOwnerCreator, Services::Installation::RuntimeDatabaseConfiguration, Services::Installation::StateMachine, Services::OperationalReadiness::BackupManifest, Services::OperationalReadiness::DiagnosticRedactor, Services::OperationalReadiness::DisasterRecoveryPolicy, Services::OperationalReadiness::OperationalHealthInspector, Services::OperationalReadiness::RestorePlan, Services::OperationalReadiness::SupportBundleBuilder, Services::Releases::ChangeFragment, Services::Releases::ConsistencyValidator, Services::Releases::NotesGenerator, Services::Releases::PerformanceBenchmark, Services::Releases::Preparation, Services::Releases::PullRequestValidator, Services::Releases::ReleaseReadinessPlaybook, Services::SecurityPrivacy, Services::Upgrades::BackupAndMaintenance, Services::Upgrades::Executor, Services::Upgrades::Inspector, Services::Upgrades::InstalledStateDetector, Services::Upgrades::Manifest, Services::Upgrades::Planner, Services::Upgrades::PostUpgradeVerifier, Services::Upgrades::RecoveryAdvisor, Services::Upgrades::Version, Services::VisualValidation::EnvironmentPreparer

## Source paths

- `test/services/application_layer/certification_test.rb`
- `test/services/commercial_readiness/entitlement_resolver_test.rb`
- `test/services/commercial_readiness/support_consent_test.rb`
- `test/services/commercial_readiness/support_identity_test.rb`
- `test/services/commercial_readiness/telemetry_policy_test.rb`
- `test/services/distributions/channel_observer_test.rb`
- `test/services/distributions/channel_state_test.rb`
- `test/services/distributions/ghcr_promotion_plan_test.rb`
- `test/services/distributions/github_release_plan_test.rb`
- `test/services/distributions/inspector_test.rb`
- `test/services/distributions/manifest_test.rb`
- `test/services/distributions/verifier_test.rb`
- `test/services/enterprise_services_test.rb`
- `test/services/epic_10/accessibility_certification_test.rb`
- `test/services/epic_10/ai_readiness_certification_test.rb`
- `test/services/epic_10/contract_validator_test.rb`
- `test/services/epic_10/domain_services_journey_test.rb`
- `test/services/epic_10/functional_framework_certification_test.rb`
- `test/services/epic_10/multitenant_extension_journey_test.rb`
- `test/services/epic_10/operational_resilience_certification_test.rb`
- `test/services/epic_10/performance_compatibility_certification_test.rb`
- `test/services/epic_10/production_deployment_certification_test.rb`
- `test/services/epic_10/rc_preparation_test.rb`
- `test/services/epic_10/rc_upgrade_certification_test.rb`
- `test/services/epic_10/rc_upgrade_fixture_test.rb`
- `test/services/epic_10/release_baseline_test.rb`
- `test/services/epic_10/representative_application_certification_test.rb`
- `test/services/epic_10/representative_application_journey_test.rb`
- `test/services/epic_10/representative_application_test.rb`
- `test/services/epic_10/security_privacy_isolation_certification_test.rb`
- `test/services/extensions/catalog_test.rb`
- `test/services/extensions/compatibility_planner_test.rb`
- `test/services/extensions/component_resolver_test.rb`
- `test/services/extensions/configuration_test.rb`
- `test/services/extensions/extension_readiness_playbook_test.rb`
- `test/services/extensions/inspector_test.rb`
- `test/services/extensions/installed_state_test.rb`
- `test/services/extensions/lifecycle_test.rb`
- `test/services/extensions/loader_test.rb`
- `test/services/extensions/manifest_test.rb`
- `test/services/extensions/registry_test.rb`
- `test/services/installation/database_configuration_test.rb`
- `test/services/installation/database_provisioner_test.rb`
- `test/services/installation/platform_owner_creator_test.rb`
- `test/services/installation/runtime_database_configuration_test.rb`
- `test/services/installation/state_machine_test.rb`
- `test/services/operational_readiness/backup_manifest_test.rb`
- `test/services/operational_readiness/diagnostic_redactor_test.rb`
- `test/services/operational_readiness/disaster_recovery_policy_test.rb`
- `test/services/operational_readiness/operational_health_inspector_test.rb`
- `test/services/operational_readiness/restore_plan_test.rb`
- `test/services/operational_readiness/support_bundle_builder_test.rb`
- `test/services/releases/change_fragment_test.rb`
- `test/services/releases/consistency_validator_test.rb`
- `test/services/releases/notes_generator_test.rb`
- `test/services/releases/performance_benchmark_test.rb`
- `test/services/releases/preparation_test.rb`
- `test/services/releases/pull_request_validator_test.rb`
- `test/services/releases/release_readiness_playbook_test.rb`
- `test/services/security_privacy_test.rb`
- `test/services/upgrades/backup_and_maintenance_test.rb`
- `test/services/upgrades/executor_test.rb`
- `test/services/upgrades/inspector_test.rb`
- `test/services/upgrades/installed_state_detector_test.rb`
- `test/services/upgrades/manifest_test.rb`
- `test/services/upgrades/planner_test.rb`
- `test/services/upgrades/post_upgrade_verifier_test.rb`
- `test/services/upgrades/recovery_advisor_test.rb`
- `test/services/upgrades/version_test.rb`
- `test/services/visual_validation/environment_preparer_test.rb`

## Relationships

- `component:Application` —TESTED_BY→ `test:Services::ApplicationLayer::Certification`
- `controller:Application` —TESTED_BY→ `test:Services::ApplicationLayer::Certification`
- `job:Application` —TESTED_BY→ `test:Services::ApplicationLayer::Certification`
- `policy:Application` —TESTED_BY→ `test:Services::ApplicationLayer::Certification`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Services::ApplicationLayer::Certification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Services::ApplicationLayer::Certification`
- `document:Distribution::Ghcr` —TESTED_BY→ `test:Services::Distributions::GhcrPromotionPlan`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Services::Epic10::AccessibilityCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Services::Epic10::AccessibilityCertification`
- `test:Services::ApplicationLayer::Certification` —TESTED_BY→ `test:Services::Epic10::AccessibilityCertification`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Services::Epic10::AiReadinessCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Services::Epic10::AiReadinessCertification`
- `test:Services::ApplicationLayer::Certification` —TESTED_BY→ `test:Services::Epic10::AiReadinessCertification`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Services::Epic10::FunctionalFrameworkCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Services::Epic10::FunctionalFrameworkCertification`
- `test:Services::ApplicationLayer::Certification` —TESTED_BY→ `test:Services::Epic10::FunctionalFrameworkCertification`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Services::Epic10::OperationalResilienceCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Services::Epic10::OperationalResilienceCertification`
- `test:Integration::ResilienceCertification` —TESTED_BY→ `test:Services::Epic10::OperationalResilienceCertification`
- `test:Services::ApplicationLayer::Certification` —TESTED_BY→ `test:Services::Epic10::OperationalResilienceCertification`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Services::Epic10::PerformanceCompatibilityCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Services::Epic10::PerformanceCompatibilityCertification`
- `test:Services::ApplicationLayer::Certification` —TESTED_BY→ `test:Services::Epic10::PerformanceCompatibilityCertification`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Services::Epic10::ProductionDeploymentCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Services::Epic10::ProductionDeploymentCertification`
- `test:Services::ApplicationLayer::Certification` —TESTED_BY→ `test:Services::Epic10::ProductionDeploymentCertification`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Services::Epic10::RcUpgradeCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Services::Epic10::RcUpgradeCertification`
- `test:Services::ApplicationLayer::Certification` —TESTED_BY→ `test:Services::Epic10::RcUpgradeCertification`
- `component:Ui::Base` —TESTED_BY→ `test:Services::Epic10::ReleaseBaseline`
- `controller:Installation::Base` —TESTED_BY→ `test:Services::Epic10::ReleaseBaseline`
- `component:Application` —TESTED_BY→ `test:Services::Epic10::RepresentativeApplicationCertification`
- `controller:Application` —TESTED_BY→ `test:Services::Epic10::RepresentativeApplicationCertification`
- `job:Application` —TESTED_BY→ `test:Services::Epic10::RepresentativeApplicationCertification`
- `policy:Application` —TESTED_BY→ `test:Services::Epic10::RepresentativeApplicationCertification`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Services::Epic10::RepresentativeApplicationCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Services::Epic10::RepresentativeApplicationCertification`
- `test:Services::ApplicationLayer::Certification` —TESTED_BY→ `test:Services::Epic10::RepresentativeApplicationCertification`
- `component:Application` —TESTED_BY→ `test:Services::Epic10::RepresentativeApplicationJourney`
- `controller:Application` —TESTED_BY→ `test:Services::Epic10::RepresentativeApplicationJourney`
- `job:Application` —TESTED_BY→ `test:Services::Epic10::RepresentativeApplicationJourney`
- `policy:Application` —TESTED_BY→ `test:Services::Epic10::RepresentativeApplicationJourney`
- `component:Application` —TESTED_BY→ `test:Services::Epic10::RepresentativeApplication`
- `controller:Application` —TESTED_BY→ `test:Services::Epic10::RepresentativeApplication`
- `job:Application` —TESTED_BY→ `test:Services::Epic10::RepresentativeApplication`
- `policy:Application` —TESTED_BY→ `test:Services::Epic10::RepresentativeApplication`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Services::Epic10::SecurityPrivacyIsolationCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Services::Epic10::SecurityPrivacyIsolationCertification`
- `test:Services::ApplicationLayer::Certification` —TESTED_BY→ `test:Services::Epic10::SecurityPrivacyIsolationCertification`
- `test:Services::Distributions::Inspector` —TESTED_BY→ `test:Services::Extensions::Inspector`

## Contract

No dedicated machine-readable contract is currently registered.

## Change checklist

- Run impact analysis for affected nodes.
- Preserve security, privacy and tenant invariants.
- Update required tests and public contracts.
- Regenerate repository intelligence artifacts.

# Integration AI Context

> Generated artifact. Source changes must be followed by regeneration.

## Responsibilities

- test: Integration::ApplicationExtensionSample, Integration::ApplicationLayerBootstrap, Integration::CommercialReadinessCertification, Integration::CompatibilityLifecycleDocumentation, Integration::DistributionCertification, Integration::DistributionObservationWorkflow, Integration::ExtensionFrameworkCertification, Integration::OperationalExamplesCertification, Integration::OperationalHealthCertification, Integration::OperationalRestoreCertification, Integration::OperatorGuidesCertification, Integration::ReleaseFrameworkCertification, Integration::RepositoryIntelligenceCertification, Integration::ResilienceCertification, Integration::SupportBundleCertification, Integration::UpgradeFrameworkCertification

## Source paths

- `test/integration/application_extension_sample_test.rb`
- `test/integration/application_layer_bootstrap_test.rb`
- `test/integration/commercial_readiness_certification_test.rb`
- `test/integration/compatibility_lifecycle_documentation_test.rb`
- `test/integration/distribution_certification_test.rb`
- `test/integration/distribution_observation_workflow_test.rb`
- `test/integration/extension_framework_certification_test.rb`
- `test/integration/operational_examples_certification_test.rb`
- `test/integration/operational_health_certification_test.rb`
- `test/integration/operational_restore_certification_test.rb`
- `test/integration/operator_guides_certification_test.rb`
- `test/integration/release_framework_certification_test.rb`
- `test/integration/repository_intelligence_certification_test.rb`
- `test/integration/resilience_certification_test.rb`
- `test/integration/support_bundle_certification_test.rb`
- `test/integration/upgrade_framework_certification_test.rb`

## Relationships

- `component:Application` —TESTED_BY→ `test:Integration::ApplicationExtensionSample`
- `controller:Application` —TESTED_BY→ `test:Integration::ApplicationExtensionSample`
- `job:Application` —TESTED_BY→ `test:Integration::ApplicationExtensionSample`
- `policy:Application` —TESTED_BY→ `test:Integration::ApplicationExtensionSample`
- `component:Application` —TESTED_BY→ `test:Integration::ApplicationLayerBootstrap`
- `controller:Application` —TESTED_BY→ `test:Integration::ApplicationLayerBootstrap`
- `job:Application` —TESTED_BY→ `test:Integration::ApplicationLayerBootstrap`
- `policy:Application` —TESTED_BY→ `test:Integration::ApplicationLayerBootstrap`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Integration::CommercialReadinessCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Integration::CommercialReadinessCertification`
- `component:Marketing::Lifecycle` —TESTED_BY→ `test:Integration::CompatibilityLifecycleDocumentation`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Integration::DistributionCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Integration::DistributionCertification`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Integration::ExtensionFrameworkCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Integration::ExtensionFrameworkCertification`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Integration::OperationalExamplesCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Integration::OperationalExamplesCertification`
- `controller:Health` —TESTED_BY→ `test:Integration::OperationalHealthCertification`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Integration::OperationalHealthCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Integration::OperationalHealthCertification`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Integration::OperationalRestoreCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Integration::OperationalRestoreCertification`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Integration::OperatorGuidesCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Integration::OperatorGuidesCertification`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Integration::ReleaseFrameworkCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Integration::ReleaseFrameworkCertification`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Integration::RepositoryIntelligenceCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Integration::RepositoryIntelligenceCertification`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Integration::ResilienceCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Integration::ResilienceCertification`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Integration::SupportBundleCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Integration::SupportBundleCertification`
- `document:Commercial-readiness::Certification` —TESTED_BY→ `test:Integration::UpgradeFrameworkCertification`
- `document:Extensions::Certification` —TESTED_BY→ `test:Integration::UpgradeFrameworkCertification`
- `test:Integration::ResilienceCertification` —TESTED_BY→ `test:Services::Epic10::OperationalResilienceCertification`

## Contract

No dedicated machine-readable contract is currently registered.

## Change checklist

- Run impact analysis for affected nodes.
- Preserve security, privacy and tenant invariants.
- Update required tests and public contracts.
- Regenerate repository intelligence artifacts.

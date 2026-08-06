# Extension Platform Certification

Phase 5 uses a production-like fixture package and a deterministic scenario
matrix to certify the extension platform from package discovery through
readiness, loading and upgrade-state observation.

The fixture at
`test/support/extension_fixtures/certification-audit/platform-extension.yml`
models a
separately installed gem. It includes a manifest, entrypoint, configuration
schema, namespaced migration path and package-local documentation. It never
performs network access and is loaded only after a ready preflight report.

## Scenario matrix

| Scenario | Expected evidence | Canonical test |
| --- | --- | --- |
| Valid package | Discovery, compatibility, bounded components, registration and sealed registry succeed | `ExtensionFrameworkCertificationTest` |
| No extensions | The community core reaches ready with an empty sealed registry | `ExtensionFrameworkCertificationTest` |
| Incompatible version | `platform_version_incompatible` blocks loading | `ExtensionFrameworkCertificationTest` |
| Missing package | `extension_package_missing` blocks loading | `ExtensionFrameworkCertificationTest` |
| Dependency cycle | `extension_dependency_cycle` blocks the complete graph | `ExtensionFrameworkCertificationTest` |
| Duplicate capability | `capability_provider_conflict` blocks the complete graph | `ExtensionFrameworkCertificationTest` |
| Entrypoint error | `extension_load_failed` omits the original message and cause | `ExtensionFrameworkCertificationTest` |
| Path traversal | A real path outside the package root is rejected | `ExtensionFrameworkCertificationTest` |
| Pending migration | Namespaced pending migration evidence is reported without execution | `ExtensionFrameworkCertificationTest` |
| Replay and equivalence | Repeated preflight is equivalent and one loader instance executes each entrypoint once | `ExtensionFrameworkCertificationTest` |

Unit suites continue to cover each contract boundary independently. The
integration suite proves that the boundaries compose without adding a hidden
extension-loading path.

## Repository Intelligence evidence

`config/ai/contracts/extensions.yml` owns the production-like fixture and
certification matrix. The `extension_readiness` playbook retrieves that
contract, runs repository validation and requires repository readiness.
`bin/extension-contract-certify` validates the schemas, executes unit and
integration tests, exercises the extension-free CLI path and verifies the
documentation and fixture evidence.

The Extension contract workflow runs this certification for changes to the
runtime, contracts, fixture, tests, guides or playbook. The full `bin/ci`
workflow remains the release-independent completion gate.

## Boundaries

Certification does not publish, download or license enterprise packages. It
does not claim process isolation for trusted Ruby code and does not execute the
fixture migration. Distribution-channel publication belongs to Epic 9 Phase 6,
and production backup and restore certification belongs to Phase 7.

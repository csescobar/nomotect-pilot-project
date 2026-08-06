# Extension Inspection and Preflight

The extension inspection engine discovers configured Bundler gems and reads
their `platform-extension.yml` files without requiring extension entrypoints.
No extension entrypoint is required or executed by either command.

## Commands

Inspect package availability and manifest identity:

```sh
bin/extensions inspect
```

Evaluate the complete compatibility graph:

```sh
bin/extensions preflight
```

By default, both commands combine `config/extensions.yml` with
`application/config/extensions.yml`. Pass
`--configuration PATH`, `--platform-version VERSION` or
`--format human|json` to select explicit inputs. The commands do not install
packages, change configuration, run migrations or persist results. A blocked
preflight exits with status 2.

## Compatibility gates

Preflight validates:

- the platform semantic-version requirement;
- the supported extension contract version;
- enabled extension dependency presence and version requirements;
- required capability presence and version requirements;
- a single provider for each capability;
- an acyclic extension dependency graph.

A ready report includes a deterministic dependency-first load order. A blocked
report exposes no load order, preventing it from being consumed accidentally.
Stable blocker codes include:

- `extension_package_missing`;
- `extension_manifest_invalid`;
- `extension_identity_mismatch`;
- `platform_version_incompatible`;
- `extension_contract_incompatible`;
- `extension_dependency_missing`;
- `extension_dependency_incompatible`;
- `extension_dependency_cycle`;
- `capability_missing`;
- `capability_version_incompatible`;
- `capability_provider_conflict`.

Inspection trusts locally installed Bundler packages and explicitly configured
packages below `application/extensions` only for metadata access.
The later loader treats compatible extensions as trusted in-process Ruby code;
this preflight is not a malware scanner or a package-signature verifier.

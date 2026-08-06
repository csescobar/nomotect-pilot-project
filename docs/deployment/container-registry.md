# Container Registry Publication

The platform publishes production images to GitHub Container Registry after the matching `main` commit passes the `CI` workflow. Container identity is derived from the repository that executes the workflow; no platform-owner namespace is embedded in the publication contract.

## Repository identity

For a repository named `acme/customer-portal`, the workflow publishes:

```text
ghcr.io/acme/customer-portal:main
ghcr.io/acme/customer-portal:sha-<first-12-characters-of-commit>
```

The workflow also records the full immutable digest:

```text
ghcr.io/acme/customer-portal@sha256:<digest>
```

This behavior applies to:

- forks;
- repositories created from a GitHub template;
- new repositories populated from a local clone;
- private application repositories.

The active repository controls the package namespace, source label, revision
label, canonical `VERSION` label, title, and publication evidence.

## Publication trigger

`.github/workflows/publish-container.yml` runs after a successful push-triggered `CI` workflow on `main`. It can also be started manually through `workflow_dispatch`.

The publication job:

1. resolves the current repository and certified source commit;
2. converts the repository path to lowercase for OCI compatibility;
3. reads the canonical platform version and applies it to the OCI version label;
4. builds `linux/amd64` and `linux/arm64` images;
5. publishes immutable commit and moving `main` tags;
6. attaches BuildKit SBOM and provenance attestations;
7. optionally creates a GitHub artifact attestation;
8. pulls the published image by digest and verifies its runtime contract;
9. uploads publication evidence containing the image name, digest, tags, source, and platforms.

## Permissions

The workflow uses the repository `GITHUB_TOKEN` with narrowly scoped permissions:

```yaml
permissions:
  contents: read
  packages: write
  attestations: write
  id-token: write
```

Repository or organization policy must allow GitHub Actions to create packages. The package visibility follows GitHub Container Registry and repository settings. A derived private repository therefore publishes its own package without receiving credentials for the original platform repository.

GitHub artifact attestations are enabled automatically for public repositories. A private repository can opt in by setting the repository variable:

```text
ENABLE_GITHUB_ATTESTATIONS=true
```

BuildKit SBOM and provenance metadata remain attached to the image regardless of this optional GitHub-specific attestation step.

## Pulling an image

Public image:

```bash
docker pull ghcr.io/acme/customer-portal:main
podman pull ghcr.io/acme/customer-portal:main
```

Private image:

```bash
echo "$GHCR_TOKEN" | docker login ghcr.io --username USERNAME --password-stdin
docker pull ghcr.io/acme/customer-portal:sha-0123456789ab
```

Use a token with only the package permissions required by the deployment environment.

## Deployment references

Use an immutable digest for the strongest deployment identity:

```text
ghcr.io/acme/customer-portal@sha256:<digest>
```

Use the commit tag when the deployment system requires tags:

```text
ghcr.io/acme/customer-portal:sha-0123456789ab
```

The `main` tag is a moving convenience pointer and should not be treated as an immutable release identifier.

Kamal separates the registry server from the image path:

```bash
export KAMAL_REGISTRY_SERVER=ghcr.io
export KAMAL_IMAGE=acme/customer-portal
export KAMAL_SOURCE=https://github.com/acme/customer-portal
```

## Version boundary

This phase intentionally publishes commit-addressable development images. Semantic tags such as `v1.0.0` remain owned by the release-engineering contract. A future release workflow may add semantic tags without changing the repository-derived image namespace or immutable digest model.

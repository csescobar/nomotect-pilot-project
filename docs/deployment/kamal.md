# Kamal Deployment Profile

This profile supports a production-like deployment with Kamal 2.12 or newer. It deploys the Rails web process through `kamal-proxy` and treats PostgreSQL as an externally managed service.

## Architecture boundary

- The application image is built from the repository `Dockerfile` production stage or pulled from an operator-selected OCI registry.
- The `web` role listens on port 3000 and is exposed through `kamal-proxy`.
- Proxy readiness uses `GET /health` and requires a successful response before traffic switches.
- PostgreSQL is not deployed as a Kamal accessory. Operators supply a production `DATABASE_URL` for a managed or separately operated PostgreSQL service.
- `/rails/storage` and `/rails/var/installation` are mounted from persistent host directories.
- Runtime secrets are injected by Kamal and are never committed to the repository.

## Required operator values

Configuration values supplied to the command environment:

- `KAMAL_IMAGE`: required registry image path without a URL scheme, such as `acme/customer-portal` when `KAMAL_REGISTRY_SERVER=ghcr.io`.
- `KAMAL_SERVER`: deployment host or IP address.
- `KAMAL_HOST`: public application hostname.
- `KAMAL_REGISTRY_USERNAME`: registry account used to push and pull images.
- `KAMAL_REGISTRY_SERVER`: optional registry server; defaults to `ghcr.io`.
- `KAMAL_SERVICE`: optional service name; defaults to `rails-application`.
- `KAMAL_SOURCE`: optional source repository URL written to deployment labels; use the current application repository URL.
- `KAMAL_SSH_USER`: optional pre-provisioned SSH user; defaults to `deploy`.
- `KAMAL_ARCH`: optional image architecture; defaults to `amd64`.

Secrets referenced by `.kamal/secrets`:

- `KAMAL_REGISTRY_PASSWORD`;
- `DATABASE_URL`;
- `SECRET_KEY_BASE`, at least 64 characters;
- `INSTALLATION_BOOTSTRAP_TOKEN` for the protected first-run installer.

Copy `.kamal/secrets.example` to `.kamal/secrets`. The real file is ignored by Git.

## Repository-derived GHCR image

The publication workflow uses the repository that executes it. A repository named `acme/customer-portal` publishes:

```text
ghcr.io/acme/customer-portal:main
ghcr.io/acme/customer-portal:sha-<commit>
```

Configure Kamal with the corresponding image path:

```bash
export KAMAL_REGISTRY_SERVER=ghcr.io
export KAMAL_IMAGE=acme/customer-portal
export KAMAL_SOURCE=https://github.com/acme/customer-portal
```

The platform repository name is never required by derived applications. Forks, repositories created from a template, and repositories created from a local clone all publish under their own GitHub owner and repository name.

## Host preparation

The selected SSH user must already be able to connect to the host and operate Docker. Create the persistence directories before the first deployment:

```bash
sudo mkdir -p /var/lib/rails-application/storage
sudo mkdir -p /var/lib/rails-application/installation
sudo chown -R deploy:deploy /var/lib/rails-application
```

Use `KAMAL_STORAGE_PATH` and `KAMAL_INSTALLATION_PATH` when the operator requires different host paths.

## Validation

Validate the complete deployment contract locally without contacting a server:

```bash
KAMAL_IMAGE=acme/customer-portal \
KAMAL_SOURCE=https://github.com/acme/customer-portal \
KAMAL_SERVER=192.0.2.10 \
KAMAL_HOST=platform.example.com \
KAMAL_REGISTRY_USERNAME=operator \
KAMAL_REGISTRY_PASSWORD=placeholder \
DATABASE_URL=postgresql://runtime:placeholder@database.example.com/platform \
SECRET_KEY_BASE=$(ruby -rsecurerandom -e 'print SecureRandom.hex(64)') \
INSTALLATION_BOOTSTRAP_TOKEN=placeholder \
bash bin/kamal-validate
```

The validator intentionally discards the rendered `kamal config` output because that command includes resolved secret values.

## First deployment

1. Confirm DNS resolves `KAMAL_HOST` to `KAMAL_SERVER`.
2. Confirm ports 80 and 443 are reachable for `kamal-proxy` and TLS issuance.
3. Confirm the external PostgreSQL service accepts the runtime connection.
4. Confirm the selected registry image exists and the registry token can pull it.
5. Run `bash bin/kamal-validate`.
6. Run `bundle exec kamal setup`.
7. Open the installation URL and complete the protected first-run wizard with the bootstrap token.

Database preparation is not run automatically by the container (`RUN_DB_PREPARE=false`). The first-run installer owns initial provisioning and migration orchestration. For an already installed deployment, run migrations through an explicit operator command before or during the approved release process.

## Redeployment and rollback boundary

Use `bundle exec kamal deploy` for normal releases and `bundle exec kamal redeploy` only when host bootstrap, proxy startup and registry login are already satisfied. Kamal retains three stopped application containers to support operational inspection and manual rollback decisions.

Prefer immutable digest or commit tags for controlled deployments. The `main` tag is convenient but moves whenever a new certified main-branch image is published.

This baseline does not claim automated database rollback. Schema changes must follow the future upgrade framework and forward-recovery guidance. Persistent uploads, installation evidence and the external database survive application-container replacement.

## Security notes

- TLS is enabled at `kamal-proxy`.
- Secrets exist only in the operator environment, ignored `.kamal/secrets`, and runtime container environment.
- The application image continues to run as the non-root `rails` user.
- Registry credentials should use scoped tokens rather than account passwords.
- Do not upload or archive the output of `kamal config`; it contains resolved secrets.

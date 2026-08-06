# Render.com Deployment

The Render profile provides a managed-platform alternative to the private VPS/Kamal path while preserving the same Rails runtime and environment contract.

## Blueprint architecture

`render.yaml` creates:

- one Docker-based web service built from the repository `Dockerfile`;
- one managed Render PostgreSQL database;
- a `/health` service health check;
- a pre-deploy database migration command;
- one persistent disk mounted at `/rails/storage`;
- operator-supplied Rails and installer secrets.

Render has an ephemeral root filesystem. The disk mounts directly at the application's upload path. The `bin/render-start` adapter creates durable subdirectories for installation state and installer branding, then links those writable application paths into the mounted storage tree:

```text
/rails/storage                         persistent disk root
/rails/storage/installation            -> /rails/var/installation
/rails/storage/branding                -> /rails/public/installation/branding
```

This adapter is provider-specific. The application continues to use the same public and installation paths as Docker Compose and Kamal deployments, while uploads already write directly to `/rails/storage`.

## Create the Blueprint

1. Connect the repository to Render.
2. Create a new Blueprint using the root `render.yaml` file.
3. Provide `SECRET_KEY_BASE` with at least 64 characters.
4. Provide a high-entropy `INSTALLATION_BOOTSTRAP_TOKEN`.
5. Review the selected service, database, region, disk size, and paid plans before applying the Blueprint.

Generate suitable values locally:

```bash
ruby -rsecurerandom -e 'puts SecureRandom.hex(64)'
ruby -rsecurerandom -e 'puts SecureRandom.hex(32)'
```

The Blueprint references the managed database through its private `connectionString`; database credentials are not committed.

## Deployment lifecycle

Render builds the production Docker image from the repository. Before each deployment, it runs:

```bash
bundle exec rails db:migrate
```

The service then starts through `bin/render-start`, which prepares the persistent paths and launches Puma. The Docker entrypoint still performs the shared production environment validation.

On the first deployment, open the protected installer and complete the remaining appearance, provisioning-evidence, and platform-administrator steps. If migrations are already current, the installer verifies and records that state rather than requiring duplicate schema changes.

## Persistence and scaling boundary

The Blueprint attaches a persistent disk because uploads, installer branding, and installation evidence must survive replacements. Render persistent disks are attached to a single service instance, so this baseline is intentionally a single-instance profile.

Before horizontally scaling the web service, move uploads and installer branding to a shared object-storage adapter and ensure installation evidence no longer depends on a single attached disk. That extension is outside this Phase 2 baseline.

## Availability trade-off

Attaching a persistent disk affects Render's normal zero-downtime deployment behavior. Operators should account for a brief service interruption during replacement and should not claim multi-instance availability from this profile.

## Validation

Validate the repository's semantic Blueprint contract with:

```bash
ruby bin/render-validate
bash -n bin/render-start
```

Render also provides Blueprint validation through its CLI or API. The repository validator remains deterministic and does not require Render credentials.

## Rollback boundary

Render can redeploy an earlier application revision, but database migrations are not automatically reversed. Treat schema changes as forward-only until the Epic 9 upgrade framework defines compatibility checks, backup evidence, and recovery guidance.

The managed database and persistent disk survive application-image replacement. They still require their own backup and restore policies.

## Security notes

- `SECRET_KEY_BASE` and `INSTALLATION_BOOTSTRAP_TOKEN` use `sync: false` and are entered during initial Blueprint creation.
- Do not place secret values directly in `render.yaml`.
- Render's private database connection is used through `DATABASE_URL`.
- The final Docker image runs as the non-root `rails` user.
- Review Render workspace access, deploy permissions, database network controls, and secret rotation procedures before production use.

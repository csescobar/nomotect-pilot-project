# Private VPS Deployment

The supported private VPS path uses the repository's Kamal 2 profile. Kamal deploys the production Docker image over SSH, runs `kamal-proxy` for TLS and traffic switching, and preserves uploads and installation evidence in host directories.

## Supported topology

- One or more Linux VPS hosts with Docker.
- A pre-provisioned SSH user that can operate Docker.
- Ports 80 and 443 reachable by `kamal-proxy`.
- DNS for `KAMAL_HOST` resolving to the deployment host.
- PostgreSQL operated separately as a managed service, a database VPS, or a host service with an independent backup lifecycle.
- Persistent host directories for `/rails/storage` and `/rails/var/installation`.

The baseline declares only the `web` role because the platform does not yet expose a separate production worker runtime contract.

## Minimum host preparation

A supported host should provide:

- a maintained Linux distribution;
- Docker Engine with a supported Compose/buildx installation;
- an SSH daemon restricted to key-based authentication;
- a non-root deployment user;
- firewall rules allowing SSH from approved operator networks and public HTTP/HTTPS traffic;
- time synchronization;
- sufficient memory for the Rails process and image replacement during deployment.

Create the persistence paths before the first deployment:

```bash
sudo mkdir -p /var/lib/nomotect-platform/storage
sudo mkdir -p /var/lib/nomotect-platform/installation
sudo chown -R deploy:deploy /var/lib/nomotect-platform
```

Set `KAMAL_STORAGE_PATH` and `KAMAL_INSTALLATION_PATH` when different host paths are required.

## Required operator environment

```bash
export KAMAL_SERVER=203.0.113.10
export KAMAL_HOST=platform.example.com
export KAMAL_SSH_USER=deploy
export KAMAL_REGISTRY_USERNAME=operator
export KAMAL_REGISTRY_PASSWORD=replace-with-scoped-token
export DATABASE_URL=postgresql://runtime:replace-me@database.internal/platform
export SECRET_KEY_BASE=$(ruby -rsecurerandom -e 'print SecureRandom.hex(64)')
export INSTALLATION_BOOTSTRAP_TOKEN=$(ruby -rsecurerandom -e 'print SecureRandom.hex(32)')
```

Keep the secret values in the ignored `.kamal/secrets` file or inject them from an operator-managed secret store.

## Preflight

Validate the local configuration without contacting the server:

```bash
VPS_PREFLIGHT_SKIP_REMOTE=true bash bin/vps-preflight
```

Run the complete preflight before deployment:

```bash
bash bin/vps-preflight
```

The remote checks confirm that SSH works, Docker is available, and both persistence directories are writable by the deployment user. The script does not install packages, alter firewall rules, or create directories.

## Deployment

For a new host:

```bash
bundle exec kamal setup
```

For a normal application update:

```bash
bundle exec kamal deploy
```

Complete the protected first-run installer after the initial deployment. Database preparation remains explicit: the installer owns initial provisioning, and later schema changes must follow the approved release or future upgrade workflow.

## PostgreSQL choices

The application contract is the same for every choice: provide a production `DATABASE_URL` and operate backups independently from application-container replacement.

1. **Managed PostgreSQL:** lowest database operational burden.
2. **Dedicated database VPS:** strong workload and failure isolation.
3. **PostgreSQL on the application VPS:** acceptable for smaller installations when resources, upgrades, monitoring, and backups are managed carefully.
4. **Separately managed database container:** supported only when its lifecycle and backups are independent from Kamal application deployments.

Do not treat the application volume as a PostgreSQL backup.

## Backup boundary

Back up these resources separately:

- PostgreSQL using database-native backup tooling;
- the host storage directory containing uploads;
- the installation-state directory;
- operator-managed secrets and deployment configuration.

Backup automation, restore certification, and disaster-recovery objectives belong to Epic 9 Phase 7. This profile documents the boundary but does not claim a complete recovery system.

## Security boundary

- Use SSH keys and disable password authentication where operationally possible.
- Use a scoped registry token instead of an account password.
- Restrict database network access to application hosts.
- Keep the operating system and Docker patched.
- Review firewall and provider security-group rules before exposing the service.
- Never commit `.kamal/secrets` or rendered `kamal config` output.

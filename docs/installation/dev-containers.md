# Dev Container and Codespaces

The repository includes one development-container contract for local VS Code Dev Containers and GitHub Codespaces.

## Start locally

1. Install Docker or a compatible container engine supported by the VS Code Dev Containers extension.
2. Open the repository in VS Code.
3. Run **Dev Containers: Reopen in Container**.
4. Wait for the post-create lifecycle to install gems and prepare PostgreSQL.
5. Start Rails:

```bash
bin/dev -b 0.0.0.0
```

Port `3000` is forwarded automatically.

## Start in Codespaces

Create a Codespace from the repository. Codespaces reads `.devcontainer/devcontainer.json`, starts the shared PostgreSQL service, installs the bundle and prepares the development database.

After creation, run:

```bash
bin/dev -b 0.0.0.0
```

## Architecture

The configuration reuses `compose.yaml` and adds only a Dev Container override that keeps the `web` service alive for editor attachment.

The dedicated Dockerfile `development` stage:

- uses the repository Ruby baseline;
- includes compiler and PostgreSQL client tools;
- runs as the non-root `vscode` user;
- stores installed gems in the shared `bundle-cache` volume;
- keeps PostgreSQL, uploads and installation state in named volumes.

The production image remains a separate final Dockerfile stage and is not used as an interactive development environment.

## Lifecycle

`post-create.sh` installs dependencies and runs `rails db:prepare` once when the environment is created.

`post-start.sh` removes a stale Rails PID and verifies that the database schema is reachable whenever the environment restarts.

Neither lifecycle script starts the Rails process automatically. This keeps process ownership visible and avoids hidden background servers.

## Secrets

The development profile uses development-only credentials declared in `compose.yaml`. Do not place production credentials, Rails master keys or deployment secrets in Dev Container configuration files.

Codespaces secrets remain operator-managed and must be referenced through environment variables only when a future development workflow explicitly requires them.

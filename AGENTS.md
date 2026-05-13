# Repository Guidelines

## Project Structure & Module Organization

This repository packages and releases Zeta4G Pro rather than hosting the main product source code. Root-level Docker assets define the runtime image:

- `Dockerfile` builds the Ubuntu-based container image and copies release binaries.
- `docker-entrypoint.sh` initializes `/data`, removes stale PID files, and maps container commands to `zeta4gctl` or `zeta4gs`.
- `docker-compose.yml` runs the published image with ports `9043`, `9044`, and `9045` and the `zeta4g-data` volume.
- `migrate-to-volume.sh` migrates host data into the Docker volume.
- `.github/workflows/release.yml` builds binaries from the private `zeta9044/zeta4g` source repo, publishes GitHub releases, and pushes Docker Hub/GHCR images.

## Build, Test, and Development Commands

- `docker compose config` validates Compose syntax.
- `docker compose up -d` starts the published Pro container locally.
- `docker compose logs --tail=50` checks startup and health output.
- `bash -n migrate-to-volume.sh` validates the migration script syntax.
- `sh -n docker-entrypoint.sh` validates the POSIX entrypoint syntax.
- `docker build --build-arg BINARIES_DIR=binaries -t zeta4g-pro:local .` builds a local image when a `binaries/` directory containing all `zeta4g*` executables is present.

## Coding Style & Naming Conventions

Keep shell scripts strict and predictable. Use `set -euo pipefail` for Bash scripts and `set -e` for POSIX `sh` entrypoints. Quote variable expansions, keep Docker image names and container names explicit, and preserve the current `zeta4g-*` binary naming. YAML files use two-space indentation.

## Testing Guidelines

There is no dedicated unit test suite in this packaging repo. Validate changes with syntax checks plus a container smoke test. For Docker changes, confirm `docker compose up -d`, `docker compose ps`, and `curl -sf http://localhost:9044/` when the service is expected to be reachable. For migration changes, test against a disposable copy of `~/.zeta4g`.

## Commit & Pull Request Guidelines

Recent history uses short conventional-style subjects such as `feat: ...`, `fix: ...`, `fix(docker): ...`, and `chore: ...`. Keep commits scoped to one operational change. Pull requests should describe runtime impact, mention release or image tags touched, list validation commands, and call out any data migration or volume behavior changes.

## Security & Configuration Tips

`--no-auth` is acceptable for local testing only. Do not add secrets, private binaries, or generated release artifacts to the repo. Keep `.claude/memory/` ignored, and avoid changing release workflow credentials unless the deployment path requires it.

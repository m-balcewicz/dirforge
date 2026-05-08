# Docker Coding Projects Guide

This guide explains what `dirforge create coding --language docker` creates, what the optional Docker bootstrap adds, and how to customize settings safely.

## Command Overview

Basic scaffold:

```bash
dirforge create coding --language docker --project llama
```

Scaffold with custom Docker settings and bootstrap helpers:

```bash
dirforge create coding \
  --language docker \
  --project llama \
  --docker-base-image python:3.12-slim \
  --docker-port 5000 \
  --docker-service api \
  --docker-bootstrap
```

## Docker-Specific Options

- `--docker-base-image <image>`
  - Base image used in `Dockerfile`
  - Default: `alpine:3.20`
  - Example: `python:3.12-slim`, `node:22-alpine`

- `--docker-port <port>`
  - Port exposed in `Dockerfile` and mapped in `docker-compose.yml`
  - Default: `8080`

- `--docker-service <name>`
  - Service key in `docker-compose.yml`
  - Default: `app`

- `--docker-bootstrap`
  - Adds local development bootstrap files (`.env`, helper scripts)
  - Optional and Docker-only

## What Gets Created

For project `llama`, the path is:

```text
CODING_WORLD/docker/llama/
```

### Always created

- `.integrity/project.yaml`
  - Metadata and timestamps for the project entry

- `README.md`
  - Project summary and language marker

- `Dockerfile`
  - Base image from `--docker-base-image`
  - `EXPOSE` set from `--docker-port`
  - Copies `src/` to `/app`

- `docker-compose.yml`
  - Service name from `--docker-service`
  - Container name `<project>_<service>`
  - Port mapping `<port>:<port>`
  - Volume mount `./src:/app`

- `.dockerignore`
  - Excludes `.git`, `.integrity`, `docs`, `tests`, `*.log`

- `src/entrypoint.sh`
  - Simple startup script placeholder

- `tests/`
  - Placeholder directory for container-related tests

- `docs/`
  - Placeholder directory for project docs

- `.gitignore`
  - Created when Git init is enabled

### Created only with `--docker-bootstrap`

- `.env`
  - Contains:
    - `APP_NAME`
    - `APP_PORT`
    - `BASE_IMAGE`
    - `SERVICE_NAME`

- `scripts/dev-up.sh`
  - Runs `docker compose up --build -d`

- `scripts/dev-down.sh`
  - Runs `docker compose down`

## Language-Level Metadata

DirForge also creates language-level metadata at:

```text
CODING_WORLD/docker/.integrity/project.yaml
```

This is managed automatically for Docker language projects.

## How to Customize After Creation

### 1. Change base image

Edit `Dockerfile`:

```dockerfile
FROM python:3.12-slim
```

Then rebuild:

```bash
docker compose build --no-cache
```

### 2. Change exposed/mapped port

Update both files:

- `Dockerfile`: `EXPOSE <port>`
- `docker-compose.yml`: `ports: - "<port>:<port>"`

Then recreate containers:

```bash
docker compose down
docker compose up --build -d
```

### 3. Rename compose service

Edit the top-level service key in `docker-compose.yml` and optionally container name.

Example:

```yaml
services:
  api:
    build: .
```

### 4. Add environment variables

If bootstrap exists, add variables to `.env`.

In `docker-compose.yml`, reference them as needed:

```yaml
environment:
  - APP_MODE=${APP_MODE:-dev}
```

### 5. Run app command instead of placeholder

Replace the compose command:

```yaml
command: ["python", "/app/main.py"]
```

Or in Dockerfile:

```dockerfile
CMD ["python", "/app/main.py"]
```

## Suggested Next Steps For Real Apps

- Add health checks to `docker-compose.yml`
- Add a non-root user in `Dockerfile`
- Pin image tags for reproducibility
- Add multi-stage builds for smaller images
- Add CI job for `docker compose config` + `docker build`

## Notes and Constraints

- Docker-specific flags are valid only with `--language docker`.
- `--no-git` still works for Docker projects.
- `--dry-run` previews all file writes without changing disk.

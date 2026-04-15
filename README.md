# skynet-base

Shared Python base image for every Skynet component. Pre-installs the wheels that appear in multiple `skynet-*` `requirements.txt` files so consumer Dockerfiles only build component-specific deps.

## Usage

```dockerfile
# syntax=docker/dockerfile:1.7
FROM docker-cache.sanscfs.dev/skynet-base:py3.12

WORKDIR /app
COPY requirements.txt .

RUN --mount=type=cache,id=pip,target=/root/.cache/pip \
    pip install \
      --extra-index-url http://nexus.nexus.svc:8081/repository/pypi-group/simple/ \
      --trusted-host nexus.nexus.svc \
      -r requirements.txt

COPY . .
CMD ["python", "-m", "app"]
```

## Tags

- `py3.12` — latest build for Python 3.12
- `py3.12-<sha>` — pinned build

Published to:
- `docker-cache.sanscfs.dev/skynet-base` (internal, primary — used by in-cluster builds)
- `ghcr.io/sanscfs/skynet-base` (external, backup)

## Contents

See `requirements-common.txt`. Adding a new dep:
1. Only add if ≥2 components use it.
2. Pin with a minor-version range (`>=0.x,<0.x+1`), not an exact `==`.
3. Commit → CI rebuilds → consumers pick it up on next `FROM` pull.

## Rebuild cadence

- On push to `requirements-common.txt` / `Dockerfile` / workflow
- Weekly cron (Monday 03:00 UTC) for upstream CVE patches
- Manual `workflow_dispatch`

## Architecture

See `sanscfs/infra/docs/github-runner-caching.md` for the full caching story.

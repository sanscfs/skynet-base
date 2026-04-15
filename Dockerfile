# syntax=docker/dockerfile:1.7
# Skynet shared Python base image.
# Pre-installs wheels common to all skynet-* components so consumer
# Dockerfiles only need to add their component-specific deps.
#
# See: https://github.com/sanscfs/infra/blob/main/docs/github-runner-caching.md

ARG PY_VERSION=3.12

# Stage 1 — build wheels with cached pip dir
FROM docker-cache.sanscfs.dev/library/python:${PY_VERSION}-slim AS wheels

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential git curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY requirements-common.txt .

RUN --mount=type=cache,id=pip,target=/root/.cache/pip \
    pip wheel --wheel-dir=/wheels \
      --extra-index-url http://nexus.nexus.svc:8081/repository/pypi-group/simple/ \
      --trusted-host nexus.nexus.svc \
      -r requirements-common.txt

# Stage 2 — slim runtime with installed site-packages
FROM docker-cache.sanscfs.dev/library/python:${PY_VERSION}-slim

COPY --from=wheels /wheels /wheels
COPY requirements-common.txt /wheels/requirements-common.txt

RUN pip install --no-index --find-links=/wheels -r /wheels/requirements-common.txt \
    && rm -rf /wheels /root/.cache

LABEL org.opencontainers.image.source=https://github.com/sanscfs/skynet-base
LABEL org.opencontainers.image.description="Skynet shared Python base — common wheels pre-installed"

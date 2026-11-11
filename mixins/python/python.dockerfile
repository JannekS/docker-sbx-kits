# Content recipe for the python mixin (companion to python.yaml).
# The final stage is a full Ubuntu image on purpose: only the files it changes
# (python3, its stdlib/deps, uv) land on the workload's rootfs, which is the
# same Ubuntu release family as docker/sandbox-templates:shell-docker.
FROM ubuntu:24.04

ARG UV_VERSION

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates curl python3 python3-pip python3-venv; \
    curl -fsSL https://astral.sh/uv/install.sh \
      | env UV_INSTALL_DIR=/usr/local/bin sh -s -- --version "${UV_VERSION}"; \
    /usr/local/bin/uv --version | grep -q "${UV_VERSION}"; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

COPY uv.toml /etc/uv/uv.toml

# Content recipe for the vibe base workload (companion to vibe.yaml).
FROM docker/sandbox-templates:shell-docker

ARG VIBE_VERSION
ARG NODE_VERSION

# Pinned Node.js, used by the socket-firewall mixin (sfw is a Node wrapper).
USER root
RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
      x86_64) narch=x64 ;; \
      aarch64) narch=arm64 ;; \
      *) echo "unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${narch}.tar.xz" -o /tmp/node.tar.xz; \
    mkdir -p /opt/node; \
    tar -xJf /tmp/node.tar.xz -C /opt/node --strip-components=1; \
    rm /tmp/node.tar.xz; \
    ln -sf /opt/node/bin/node /usr/local/bin/node; \
    ln -sf /opt/node/bin/npm /usr/local/bin/npm; \
    ln -sf /opt/node/bin/npx /usr/local/bin/npx; \
    ln -sf /opt/node/bin/corepack /usr/local/bin/corepack

# mistral-vibe from PyPI, pinned by the descriptor's version arg. uv ships
# with the shell-docker template.
USER agent
RUN set -eux; \
    uv tool install "mistral-vibe==${VIBE_VERSION}"; \
    uv cache clean; \
    test "$(command -v vibe)" = "/home/agent/.local/bin/vibe"; \
    vibe --version | grep -q "${VIBE_VERSION}"

ENV PATH=/home/agent/.local/bin:${PATH} \
    VIBE_ENABLE_TELEMETRY=false \
    VIBE_ENABLE_AUTO_UPDATE=false \
    GIT_TERMINAL_PROMPT=0

WORKDIR /home/agent/workspace
ENTRYPOINT ["sh", "-c", "if [ -n \"${VIBE_AGENT:-}\" ]; then exec vibe --trust --agent \"$VIBE_AGENT\"; else exec vibe --trust; fi"]
CMD []

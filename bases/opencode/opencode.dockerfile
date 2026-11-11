# Content recipe for the opencode base workload (companion to opencode.yaml).
FROM docker/sandbox-templates:shell-docker

ARG OPENCODE_VERSION
ARG NODE_VERSION

# Pinned Node.js for the agent installer and for the socket-firewall mixin
# (sfw is a Node wrapper around a prebuilt binary).
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

# OpenCode from npm, pinned by the descriptor's version arg.
USER agent
RUN set -eux; \
    npm install -g "@opencode/cli@${OPENCODE_VERSION}"; \
    test "$(command -v opencode)" = "/home/agent/.local/bin/opencode"; \
    opencode --version | grep -q "${OPENCODE_VERSION}"

ENV PATH=/home/agent/.local/bin:${PATH} \
    OPENCODE_DISABLE_AUTOUPDATE=1 \
    GIT_TERMINAL_PROMPT=0

WORKDIR /home/agent/workspace
ENTRYPOINT ["opencode"]
CMD []

# Content recipe for the typescript mixin (companion to typescript.yaml).
# Installs pnpm into a Node build stage and copies only pnpm's files; the
# Node.js runtime itself is provided by the composed workload.
FROM node:26-bookworm-slim AS build
ARG PNPM_VERSION
RUN set -eux; \
    npm install -g "pnpm@${PNPM_VERSION}"; \
    pnpm --version | grep -q "${PNPM_VERSION}"

FROM scratch
COPY --from=build /usr/local/bin/pnpm /usr/local/bin/pnpm
COPY --from=build /usr/local/bin/pnpx /usr/local/bin/pnpx
COPY --from=build /usr/local/lib/node_modules/pnpm /usr/local/lib/node_modules/pnpm
COPY --chown=1000:1000 npmrc /home/agent/.npmrc
COPY --chown=1000:1000 pnpm-config.yaml /home/agent/.config/pnpm/config.yaml

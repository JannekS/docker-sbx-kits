# Content recipe for the socket-firewall mixin (companion to socket-firewall.yaml).
# sfw is distributed as an npm wrapper around a prebuilt binary; the wrapper
# script needs Node.js at runtime, which the composed workload provides
# (declared via requires: node >= 20).
FROM node:26-bookworm-slim AS build
ARG SFW_VERSION
RUN npm install -g "sfw@${SFW_VERSION}"

FROM scratch
COPY --from=build /usr/local/bin/sfw /usr/local/bin/sfw
COPY --from=build /usr/local/lib/node_modules/sfw /usr/local/lib/node_modules/sfw

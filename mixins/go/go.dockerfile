# Content recipe for the go mixin (companion to go.yaml).
ARG GO_VERSION=1.27.3
FROM golang:${GO_VERSION}-bookworm AS build

# Language tooling, built static so they run on the workload's libc.
RUN set -eux; \
    export CGO_ENABLED=0; \
    go install golang.org/x/tools/gopls@latest; \
    go install mvdan.cc/gofumpt@latest; \
    go install github.com/go-delve/delve/cmd/dlv@latest; \
    go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest; \
    ls /go/bin

FROM scratch
COPY --from=build /usr/local/go /usr/local/go
COPY --from=build /go/bin /go/bin

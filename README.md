# sbx-kits — composable Docker Sandbox kits (kit spec v3)

Composable kits for running coding agents in [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/),
authored against the [v3 kit specification](https://github.com/docker/sandbox-kit-spec).

## Layout

```
bases/                  kind: workload — one per agent harness
  opencode/             OpenCode agent (npm @opencode/cli, pinned)
  vibe/                 Mistral Vibe agent (PyPI mistral-vibe, pinned)
mixins/                 kind: mixin — composable tool kits
  socket-firewall/      Socket Firewall (sfw) in every sandbox
  python/               python3 + pinned uv, 3-day release cooldown
  typescript/           pinned pnpm, 3-day cooldown, no scripts by default
  go/                   latest Go (pinned arg) + gopls, gofumpt, delve, golangci-lint
sets/                   kind: set — one workload + socket-firewall + one language kit
  opencode-python/  opencode-typescript/  opencode-go/
  vibe-python/      vibe-typescript/      vibe-go/
```

## Inference providers (both harnesses)

Both bases declare the same two proxy-managed credentials (all `optional: true`,
so a sandbox still starts unbound):

| Provider | Host credential service (`sbx secret set <service>`) | Env var in sandbox | Inject domain |
|---|---|---|---|
| Mistral La Plateforme | `mistral` | `MISTRAL_API_KEY` (sentinel) | `api.mistral.ai`, `chat.mistral.ai`, `console.mistral.ai` |
| OpenCode Go (`https://opencode.ai/inference/go/...`) | `opencode` | `OPENCODE_API_KEY` (sentinel) | `opencode.ai` |

The real keys never enter the sandbox; the host proxy substitutes them on
outbound requests to the listed domains only. Each base also registers the
providers in its agent's config (`~/.config/opencode/opencode.json` /
`~/.vibe/config.toml`) via a startup hook.

Host setup:

```console
$ sbx secret set mistral   # paste MISTRAL_API_KEY
$ sbx secret set opencode   # paste OPENCODE_API_KEY
```

## Security posture per language kit

- **Python**: `UV_EXCLUDE_NEWER` is recomputed on every sandbox start to
  `now - 3 days` (startup hook writing to `/etc/sandbox-persistent.sh`), so uv
  refuses packages published less than 3 days ago. `/etc/uv/uv.toml` sets
  `python-downloads = "never"` (no standalone Python downloads) and
  `link-mode = "copy"`. Change the cooldown with `--kit-arg python.cooldown_days=N`.
- **TypeScript**: pnpm `minimumReleaseAge: 4320` (minutes = 3 days) in both
  `~/.npmrc` (pnpm 10) and `~/.config/pnpm/config.yaml` (pnpm 11+), plus
  `enable-pre-post-scripts=false`; dependency build scripts do not run unless
  allow-listed per project (pnpm 10+ default, none allow-listed here).
- **Go**: Go pinned by `go_version` arg (default `1.27.3`, the current stable);
  bump via `--build-arg go_version=<x.y.z>` and republish. Module downloads go
  through `proxy.golang.org`/`sum.golang.org` only.
- **Every sandbox**: the `socket-firewall` mixin installs `sfw` and appends
  shell functions (`npm() { sfw npm "$@"; }` etc. for npm, npx, pnpm, yarn,
  uv, pip, pip3, cargo) to `/etc/sandbox-persistent.sh`, which every bash
  session sources via `BASH_ENV` — so installs are transparently checked by
  Socket Firewall Free (no API key needed). Go commands (`go get`,
  `go install`, `go mod`) are deliberately **not** wrapped: the free tier does
  not scan Go modules. The mixin declares `requires: node >= 20`, which both
  bases provide.

## Build, publish, test

**Publishing is only required for the `kind: set` descriptors**: the v3 spec
requires a set's `kits:` entries to be published registry references (local
paths are refused), so `sets/*` use the `docker.io/NAMESPACE` placeholder —
fill it in only if you later publish. **Local testing needs no registry at
all** — point `sbx` at the directories and it builds them on demand:

```console
$ sbx run ./bases/opencode --name test \
    --kit ./mixins/socket-firewall --kit ./mixins/python
$ sbx run ./bases/vibe --name test-ts \
    --kit ./mixins/socket-firewall --kit ./mixins/typescript
```

To validate a descriptor + recipe build without publishing:

```console
$ docker buildx build ./bases/vibe --file ./bases/vibe/vibe.yaml --output type=cacheonly
```

When you do want to publish, build mixins and bases first, then the sets
(replace `docker.io/NAMESPACE` in `sets/*` with your namespace):

```console
$ docker login
$ docker buildx build bases/opencode -f bases/opencode/opencode.yaml \
    -t docker.io/NAMESPACE/opencode:1.0.0 --push
$ docker buildx build mixins/socket-firewall -f mixins/socket-firewall/socket-firewall.yaml \
    -t docker.io/NAMESPACE/socket-firewall:1.0.0 --push
$ docker buildx build mixins/python -f mixins/python/python.yaml \
    -t docker.io/NAMESPACE/python:1.0.0 --push
# ... typescript, go, vibe ...
$ docker buildx build sets/opencode-python -f sets/opencode-python/opencode-python.yaml \
    -t docker.io/NAMESPACE/opencode-python:1.0.0 --push
```

Useful build args (descriptor `args` with `buildArg`): `version` (agent / sfw /
uv / pnpm pin) and `go_version`, `node_version`.

## Run

```console
$ sbx run docker.io/NAMESPACE/opencode-python:1.0.0 --name my-project
$ sbx run docker.io/NAMESPACE/vibe-go:1.0.0 --name my-project
```

Or compose locally without publishing, using `--kit`:

```console
$ sbx run ./bases/opencode --name test \
    --kit ./mixins/socket-firewall --kit ./mixins/python
```

## Notes / caveats

- Version defaults were pinned at authoring time (opencode 2.0.29, vibe 2.25.8,
  node 26.13.0, uv 0.9.25, pnpm 10.16.0, sfw 2.0.6, go 1.27.3). Bump via the
  kit args and republish.
- Both bases build on `docker/sandbox-templates:shell-docker` (the base the
  official v3 contrib kits use). Docker's Mistral Vibe guide uses
  `docker.io/sbx/shell-docker-image:latest` instead; either works — swap the
  `FROM` line if you prefer the guide's base.
- The exact `~/.vibe/config.toml` provider schema should be verified against
  the pinned `mistral-vibe` release; the OpenCode `opencode.json` provider
  blocks follow OpenCode's custom-provider format (`@ai-sdk/openai-compatible`
  + `{env:VAR}` key references).
- Socket Firewall Free filters package-artifact network requests; cached
  artifacts are not re-scanned. It supports npm/yarn/pnpm/pip/uv/cargo (Go
  modules need the Enterprise tier).

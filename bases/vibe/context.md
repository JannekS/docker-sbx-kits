# Sandbox context for Mistral Vibe

- This sandbox runs Vibe. Two inference providers are preconfigured in
  `~/.vibe/config.toml`: `mistral` (Mistral La Plateforme) and `opencode-go`
  (OpenCode Go). API keys are proxy-managed: `MISTRAL_API_KEY` /
  `OPENCODE_API_KEY` hold sentinels and the sandbox proxy injects the real
  keys only into `api.mistral.ai` / `opencode.ai`.
- Package installs (npm, pnpm, uv, pip, cargo) are routed through Socket
  Firewall (`sfw`) via shell functions defined in `/etc/sandbox-persistent.sh`.
- Export environment variables needed by later shell sessions in
  `/etc/sandbox-persistent.sh`.

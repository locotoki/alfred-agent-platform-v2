# 2025-05-28 · Redis "slave-of-me" compromise

| ✅ Fixed item | Detail |
|--------------|--------|
| **Auth on Redis** | `requirepass`, bind 127.0.0.1, `protected-mode yes` |
| **Dangerous cmds** | `SLAVEOF`, `CONFIG`, `MODULE`, `FLUSH*` renamed/disabled |
| **Secrets rotated** | Slack tokens, JWT, Redis, Keycloak, PATs |
| **Slack flow** | `slack_mcp_gateway` → Redis stream → **echo-agent** sidecar → `agent-core` |
| **Falco rule** | Alerts on Redis `SLAVEOF|CONFIG|MODULE` |
| **Nightly** | Trivy scan & secret push-protection enabled |

_All changes committed in this PR; see `docker-compose.override.yml` and `.github/workflows/nightly-trivy.yml`._

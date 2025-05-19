# Orchestration PoC – secrets & environment

| Key | Scope | Purpose | Example |
|-----|-------|---------|---------|
| CREWAI_ENDPOINT | n8n / CI | CrewAI base URL | http://crewai:8080 |
| CREWAI_API_KEY | n8n | Bearer token | local-test |
| SLACK_WEBHOOK_URL | n8n | Escalation target | https://hooks.slack.com/… |
| N8N_BASIC_AUTH_USER/_PASSWORD | n8n | Console auth | admin / admin |
| ALERT_WEBHOOK_SHARED_SECRET | optional | HMAC from AM | |
| KUBECONFIG | n8n exec | `kubectl` perms | /var/run/… |

Populate as repo-level *secrets* for CI.

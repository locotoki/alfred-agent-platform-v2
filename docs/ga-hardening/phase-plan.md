# GA-Hardening Phase Plan · v3.0.0

| Work-Stream | Owner | Start | Done-By | Exit Criteria |
|-------------|-------|-------|---------|---------------|
| Credential Reconciliation (Postgres/Redis) | @secops | 29 May | 31 May | All containers healthy, 0 auth failures |
| Healthcheck Standardisation | @platform | 29 May | 02 Jun | 100 % services expose /health, Docker HC green |
| Broken Dependency Cleanup (ui-chat, crm-sync) | @web | 29 May | 30 May | Images build & pass smoke tests |
| Observability Baseline & Alerts | @infra | 30 May | 03 Jun | p95 panel live, alert rules merged |
| E2E Smoke & Regression Suite | @qa | 30 May | 04 Jun | `/alfred health` + Slack CI green |
| Documentation & Runbooks | @docs | 29 May | 05 Jun | Runbooks reviewed, published |
| Phase Retrospective & Sign-off | @admin | 05 Jun | 06 Jun | All exit criteria met, bench ≤ 75 s |

## Milestones
* **Kick-off:** 29 May 09:00 UTC
* **Mid-sprint check:** 02 Jun 17:00 UTC
* **Sign-off:** 06 Jun 12:00 UTC

## Risks & Mitigations
* **Secret drift** — lock via vault automation
* **Test flakiness** — dedicate CI runner pool
* **Scope creep** — freeze backlog on 31 May

## Communication
* Daily stand-up in #ga-hardening 09:30 UTC
* Status board: Github Projects "GA-Hardening" column view

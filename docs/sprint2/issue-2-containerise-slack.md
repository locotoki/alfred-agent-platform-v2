### Containerise Slack Adapter
*Labels:* size/M · type/feature · codex
*Linked ADR:* ADR-001

#### Acceptance Criteria
- [ ] Add `alfred/adapters/slack/Dockerfile`
      • base `python:3.11-slim`
      • `poetry install --only main`
- [ ] Expose port `3000`
- [ ] Health-check endpoint `/healthz` returns JSON `{status:"ok"}`
- [ ] Update `docker-compose.yml` with service `slack-adapter`
- [ ] Makefile target `make run-slack-adapter`
- [ ] Smoke test: `docker compose up -d slack-adapter && curl -f localhost:3000/healthz`

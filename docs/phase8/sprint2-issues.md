# Sprint 2 Issue Cards

### API Gateway CI Job
*Labels:* size/S · type/ci · codex
*Linked ADR:* ADR-001

#### Acceptance Criteria
- [ ] Add GitHub Action workflow `ci-adapters.yml`
- [ ] Run pytest with marker `adapters`
- [ ] Fail on coverage < 85%
- [ ] Upload coverage XML to Codecov

---

### Containerise Slack Adapter
*Labels:* size/M · type/feature · codex
*Linked ADR:* ADR-001

#### Acceptance Criteria
- [ ] Add `Dockerfile` under `alfred/adapters/slack/`
- [ ] Base `python:3.11-slim`, poetry install
- [ ] Healthcheck `/healthz` returns 200
- [ ] Update `docker-compose.yml` (expose 3000 → 8000)
- [ ] Smoke test: `docker compose up -d slack-adapter && curl localhost:3000/healthz`

---

### Integrate IntentRouter with Orchestrator
*Labels:* size/M · type/feature · codex

#### Acceptance Criteria
- [ ] Orchestrator calls `IntentRouter.route()` before any LLM call
- [ ] On "unknown_intent" skip LLM and respond with help message
- [ ] Add unit test: unknown intent bypasses adapter (token counter stays flat)
- [ ] Prometheus metric `alfred_orchestrator_route_total`

---

### Cost Dashboard Prometheus → Grafana
*Labels:* size/S · type/ops · codex

#### Acceptance Criteria
- [ ] Grafana dashboard `LLM-Costs` with panels:
   • `alfred_llm_tokens_total` (rate)
   • $ estimate (tokens × price)
   • Per-intent volume
- [ ] JSON dashboard committed under `metrics/grafana/`

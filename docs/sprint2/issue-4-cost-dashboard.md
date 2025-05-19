### Cost Dashboard Prometheus → Grafana
*Labels:* size/S · type/ops · codex

#### Acceptance Criteria
- [ ] Grafana dashboard `LLM-Costs.json` with panels:
      • `rate(alfred_llm_tokens_total[5m])`
      • Monthly $ spend projection (tokens × price)
      • Per-intent volume
- [ ] Commit JSON under `metrics/grafana/`
- [ ] Add dashboard to provisioning in `docker-compose-grafana.yml`

# ✨ Summary
Adds standard Prometheus health-checks with a dedicated DB metrics side-car and Grafana dashboard.

## 🚀 Components
1. `services/db-metrics/` – FastAPI app exposing `/health` and Prom metrics.
2. Prometheus scrape job + Helm values toggle.
3. Grafana dashboard `db-health-dashboard.json`.
4. Setup/teardown script `scripts/setup-db-metrics.sh`.

## ✅ Verification (CI)
| Gate | Result |
|------|--------|
| lint | PASS |
| tests | PASS |
| db-metrics-smoke | PASS |
| slack-smoke | PASS |
| orchestration-integration | PASS |

## 📊 Dashboard preview
![preview](GRAFANA-DASHBOARD-PREVIEW.md)

## 🔮 Next steps
* Auto-scale DB metrics Pod on API error rate.
* Add MSSQL and Postgres exporters.
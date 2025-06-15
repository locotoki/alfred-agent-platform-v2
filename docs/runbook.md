- For Apple-silicon & WSL quirks, see **docs/local-dev.md**.

## Alert Runbook

### ColdStartSLAExceeded

| Trigger | Vector-ingest cold-start benchmark exceeds 60 s (nightly) |
|---------|-----------------------------------------------------------|
| Alerts  | Slack `#oncall` (via Alertmanager `slack_oncall` receiver)|
| Action  | 1. Look at Grafana "Cold-Start" dashboard<br>2. Check recent image size changes<br>3. Rebuild offending service with `--no-cache` and re-run bench |
| Owner   | Platform Engineering (contact @team-infra) |

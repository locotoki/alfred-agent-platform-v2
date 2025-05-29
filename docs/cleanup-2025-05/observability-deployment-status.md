# Observability Stack Deployment Status

## ✅ Services Running

- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3030 (admin/admin)
- **Alertmanager**: http://localhost:9093

## 📋 Next Steps

### 1. Create Grafana API Key
1. Visit http://localhost:3030
2. Login with admin/admin
3. Navigate to Settings → API Keys → New API Key
4. Create key with Admin role
5. Copy the generated key

### 2. Import Dashboards
Once you have the API key, run:
```bash
GRAFANA_KEY="your-api-key-here"
for json in infra/grafana/dashboards/observability/*.json; do
  curl -sS -H "Authorization: Bearer $GRAFANA_KEY" \
       -H "Content-Type: application/json" \
       -X POST http://localhost:3030/api/dashboards/db -d @"$json"
done
```

### 3. Configure Slack Webhook
1. Get webhook URL from Slack admin for #alerts-prod channel
2. Update Alertmanager config:
```bash
SLACK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
docker exec alfred-agent-platform-v2-alertmanager-1 sh -c \
  "sed -i 's|PLACEHOLDER|${SLACK_URL#https://hooks.slack.com/services/}|' /etc/alertmanager/alertmanager.yml"
docker compose -f docker-compose.yml -f docker-compose.observability.yml kill -s HUP alertmanager
```

### 4. Test Alert
To trigger a test alert, you can:
- Generate high latency traffic to trigger p95 alert
- Or manually create an alert via Prometheus API

## 🔧 Configuration Files

- Prometheus config: `observability/prometheus/prometheus.yml`
- Alert rules: `observability/prometheus/alert_rules.yml`
- Alertmanager config: `observability/alertmanager/alertmanager.yml`
- Grafana data: `observability/grafana/`

## 🚨 Known Issues

- Grafana port changed from 3000 to 3030 to avoid conflict with db-api
- Alertmanager needs actual Slack webhook URL (currently placeholder)
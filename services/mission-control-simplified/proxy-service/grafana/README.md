# Niche-Scout Grafana Dashboards

This directory contains Grafana dashboard definitions and provisioning configuration for monitoring the Niche-Scout proxy service.

## Dashboard Overview

Two primary dashboards are included:

### 1. Niche-Scout Overview Dashboard

Primary operational dashboard showing key metrics and performance trends.

![Niche-Scout Overview Dashboard](https://i.imgur.com/vNDmWKg.png)

Features:
- **Key Metrics Section**: 
  - Error Rate gauge (with 3% threshold)
  - P95 Latency gauge (with 400ms/800ms thresholds)
  - Cache Hit Ratio gauge (with 20% threshold)

- **Performance Trends**:
  - P95 Latency over time
  - Error Rate over time
  - Transformation duration (P50/P95)

- **System Health**:
  - CPU Usage
  - Memory Usage

- **API Stats**:
  - Request Rate
  - Requests by Status
  - Social Intel API Response Time
  - Match Types
  - Relevance Scores by Query

### 2. Niche-Scout Alerts Dashboard

Dashboard dedicated to monitoring alert status and thresholds.

![Niche-Scout Alerts Dashboard](https://i.imgur.com/ZnF9dMD.png)

Features:
- **Alert Status**: 
  - High Error Rate
  - High Latency
  - Low Cache Hit Ratio
  - Service Down

- **Alert Thresholds**:
  - Error Rate vs Threshold
  - P95 Latency vs Threshold

- **Alert History**:
  - Timeline of alert firing events by alert name

## How to Access Dashboards

Once the system is running:

1. Access Grafana at: http://localhost:3000
2. Login with default credentials (admin/admin)
3. Navigate to Dashboards → Niche-Scout

## Provisioning Configuration

The dashboards are automatically provisioned when Grafana starts through Docker Compose:

- `provisioning/datasources/prometheus.yml`: Configures Prometheus as the default data source
- `provisioning/dashboards/dashboard.yml`: Configures dashboard provisioning
- `provisioning/dashboards/*.json`: The dashboard definition files

## Manual Import 

If you need to import the dashboards manually:

1. Go to Grafana (http://localhost:3000)
2. Navigate to Dashboards → Import
3. Upload one of the JSON files from the `provisioning/dashboards/` directory
4. Select the Prometheus data source when prompted

## Alert Testing

To test alerts visualization on the dashboard:

```bash
# Generate test data that will trigger alerts
../scripts/test-alerts.sh --fire error

# View alerts in the dashboard
# http://localhost:3000/d/niche-scout-alerts
```

## Adding Custom Dashboards

To add a custom dashboard:

1. Create it in the Grafana UI
2. Save it
3. Export it to JSON (Share Dashboard → Export → Save to file)
4. Place the JSON file in `provisioning/dashboards/`
5. Restart Grafana to pick up the changes

## Monitoring SLOs

The dashboards are configured with the following SLO thresholds:

- **Latency**: 
  - Target: p95 < 400ms
  - Warning: p95 > 400ms
  - Critical: p95 > 800ms

- **Error Rate**:
  - Target: < 1%
  - Warning: > 3%
  - Critical: > 5%

- **Cache Hit Ratio**:
  - Target: > 50%
  - Warning: < 20%
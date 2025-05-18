# Alert Service SLO Dashboard

This document describes the Alert Service SLO Dashboard for monitoring key performance indicators and service level objectives.

## Overview

The Alert Service SLO Dashboard provides real-time monitoring of critical metrics to ensure the alert service meets its service level objectives (SLOs).

## Dashboard Location

- **Grafana URL**: `/d/alert-slo-v11/alert-service-slo-dashboard`
- **Dashboard File**: `monitoring/grafana/dashboards/alert_slo_v11.json`

## Service Level Objectives

### 1. Alert Accuracy SLO
- **Target**: ≥ 98% accuracy (≤ 2% false positive rate)
- **Measurement**: `(1 - false_positives / total_alerts) * 100`
- **Alert Threshold**: Triggers when accuracy drops below 98% for 5 minutes
- **Panel**: Top-left timeseries chart showing real-time accuracy

### 2. Response Time SLO
- **Target**: P99 latency ≤ 500ms
- **Measurement**: `histogram_quantile(0.99, alert_processing_duration)`
- **Alert Threshold**: Triggers when P99 exceeds 500ms for 5 minutes
- **Panel**: Middle-left timeseries showing P95 and P99 response times

### 3. Success Rate SLO
- **Target**: ≥ 99.9% success rate
- **Measurement**: `(1 - errors / total_alerts) * 100`
- **Alert Threshold**: Triggers when success rate drops below 99.9% for 5 minutes
- **Panel**: Bottom-left timeseries tracking processing success rate

## Dashboard Panels

![Dashboard Overview](/docs/images/slo-dashboard-overview.png)

### Real-time Metrics (Left Column)
1. **Alert Accuracy SLO**: Line chart showing accuracy percentage over time
2. **Alert Processing Time SLO**: P95/P99 latency trends
3. **Alert Processing Success Rate**: Success rate percentage

### 24-Hour Summary (Right Column)
1. **Alert Accuracy (24h)**: Gauge showing current 24-hour accuracy
2. **P99 Response Time (24h)**: Gauge displaying 24-hour P99 latency
3. **Success Rate (24h)**: Gauge with current 24-hour success rate

## Alert Rules

Automated alerts are configured in `monitoring/grafana/alerts/alert_slo_rules.yaml`:

### Alert Accuracy Below SLO
- **Severity**: Warning
- **Condition**: Accuracy < 98% for 5 minutes
- **Team**: Platform
- **Action**: Review false positive patterns, tune ML model

### Alert Processing Time Exceeds SLO
- **Severity**: Critical
- **Condition**: P99 latency > 500ms for 5 minutes
- **Team**: Platform
- **Action**: Scale infrastructure, optimize processing pipeline

### Alert Processing Success Rate Below SLO
- **Severity**: Warning
- **Condition**: Success rate < 99.9% for 5 minutes
- **Team**: Platform
- **Action**: Investigate errors, review service health

## Using the Dashboard

### Accessing the Dashboard
1. Navigate to Grafana: `https://grafana.your-domain.com`
2. Go to Dashboards → Alert Service SLO Dashboard
3. Or use direct link: `/d/alert-slo-v11/alert-service-slo-dashboard`

### Time Range Selection
- Default view: Last 6 hours
- Adjust using the time picker in the top-right
- Auto-refresh: Every 10 seconds

### Drilling Down
1. Click any panel title for detailed view
2. Use legends to toggle specific metrics
3. Hover over graphs for precise values
4. Click alerts for investigation links

## Troubleshooting

### Missing Data
If panels show "No Data":
1. Verify Prometheus is running: `kubectl get pods -n monitoring`
2. Check metric names in Prometheus: `/metrics`
3. Ensure alert service is exporting metrics

### Alert Not Firing
If SLO breaches but alerts don't fire:
1. Check alert rule syntax in Grafana
2. Verify notification channels are configured
3. Review alert state in Grafana Alerting tab

### Performance Issues
If dashboard loads slowly:
1. Reduce time range to last 1-2 hours
2. Check Prometheus query performance
3. Consider adding recording rules for complex queries

## Maintenance

### Dashboard Updates
1. Edit JSON in `monitoring/grafana/dashboards/alert_slo_v11.json`
2. Reload in Grafana or restart Grafana pod
3. Test all panels and alerts after changes

### Metric Changes
If metrics are renamed or added:
1. Update queries in dashboard JSON
2. Modify alert rules accordingly
3. Update this documentation

## Related Documentation

- [Alert Service Architecture](/docs/alerts/architecture.md)
- [Prometheus Metrics Guide](/docs/monitoring/prometheus.md)
- [Grafana Administration](/docs/monitoring/grafana-admin.md)
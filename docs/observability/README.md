# Observability v2 Dashboard Documentation

## Overview

The Observability v2 dashboard provides enhanced monitoring capabilities for the Alfred platform, focusing on request latency, error budgets, and service health metrics.

## Dashboard Panels

### 1. Request Latency Percentiles (P50/P95/P99)
**Purpose**: Tracks response time distribution across services to identify performance degradation.

**Key Features**:
- Real-time percentile calculations (P50, P95, P99)
- Alert thresholds: P95 > 500ms (yellow), P99 > 1s (red)
- Click-through to Loki logs for detailed investigation

**PromQL Query**:
```promql
histogram_quantile(0.95,
  sum by (le) (
    rate(http_request_duration_seconds_bucket{env=~"$environment",job=~"$service"}[5m])
  )
)
```

### 2. Error Budget Burn-Down
**Purpose**: Visualizes SLO compliance and error budget consumption rate.

**Key Features**:
- Stacked visualization showing budget remaining vs error rate
- Real-time burn rate calculation
- Color-coded thresholds for budget status

**PromQL Query**:
```promql
# Budget Remaining
1 - (
  sum(rate(http_requests_total{status!~"2..",env=~"$environment",job=~"$service"}[1m])) /
  sum(rate(http_requests_total{env=~"$environment",job=~"$service"}[1m]))
)
```

### 3. 7-Day Burn Rate Sparkline
**Purpose**: Quick visual indicator of error budget consumption trend.

**Calculation**: Error rate divided by SLO target (1% error budget)
- Green: < 1x (within budget)
- Yellow: 1-2x (consuming budget faster than expected)
- Red: > 2x (critical burn rate)

### 4. Service Availability Heatmap
**Purpose**: Visual representation of service uptime across time periods.

**Features**:
- Y-axis: Services
- X-axis: Time
- Color intensity: Availability percentage
- Green (100%) to Red (0%)

### 5. Alert Effectiveness
**Purpose**: Measures alert quality to reduce noise and improve actionability.

**Metrics**:
- Actionable alerts: Required human intervention
- Non-actionable alerts: Auto-resolved or false positives

## Template Variables

The dashboard includes the following template variables for filtering:

1. **environment**: Filter by deployment environment (dev, staging, prod)
2. **service**: Multi-select service filter

## Usage Guide

### Accessing the Dashboard
1. Navigate to Grafana: `https://grafana.alfred.platform/`
2. Search for "Observability v2 - Enhanced Metrics"
3. Select your environment and services from the dropdown

### Interpreting Metrics

**Latency Analysis**:
- P50: Median response time (50% of requests)
- P95: 95% of requests complete within this time
- P99: 99% of requests complete within this time

**Error Budget**:
- 100%: No errors, full budget available
- 99%: 1% error rate, matching SLO target
- <95%: Approaching budget exhaustion, investigate issues

### Setting up Alerts

Example alert rule for latency:
```yaml
- alert: HighP95Latency
  expr: histogram_quantile(0.95, sum by (job) (rate(http_request_duration_seconds_bucket[5m]))) > 0.5
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High P95 latency for {{ $labels.job }}"
```

## Screenshots

### Main Dashboard View
```
┌─────────────────────────────────────────────────────────────────┐
│                    Observability v2 - Enhanced Metrics           │
├─────────────────────────────────┬───────────────────────────────┤
│  Request Latency (P50/P95/P99)  │    Error Budget Burn-Down     │
│                                 │                                │
│  1s ┤              ╱─── P99    │  100% ┤████████████░░░        │
│     │            ╱╱            │       │                        │
│500ms┤        ╱───── P95        │   99% ┤─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │
│     │    ╱────                 │       │                        │
│100ms┤╱──────────── P50         │   98% ┤      Error Rate       │
│     └───────────────────────   │       └────────────────────    │
├─────────────────────────────────┴───────────────────────────────┤
│              Service Availability Heatmap         │ 7-Day Burn  │
│  alfred-core  ████████████████████████████████   │   1.2x ⚠️    │
│  slack-app    ███████████░████████████████████   ├──────────────┤
│  model-router ████████████████████████████████   │Alert Effect. │
│  redis        ████████████████████████████████   │ ◐ 73% Action │
└─────────────────────────────────────────────────────────────────┘
```

## Troubleshooting

### Common Issues

1. **No data in panels**
   - Verify Prometheus datasource is configured
   - Check service labels match your environment
   - Ensure metrics are being exported

2. **Slow dashboard loading**
   - Reduce time range (default 24h)
   - Use service filter to limit queries
   - Check Prometheus performance

3. **Missing Loki logs link**
   - Verify Loki datasource is configured
   - Check log labels match service names

## Related Resources

- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Grafana Panel Reference](https://grafana.com/docs/grafana/latest/panels/)
- [SRE Workbook - Error Budgets](https://sre.google/workbook/error-budgets/)
- [Alert Grouping Documentation](../dev/alert-grouping.md)

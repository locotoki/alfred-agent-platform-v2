# Alert Rules Documentation

This document provides information about the alert rules configured for the Alfred Agent Platform.

## Service Health Alerts

The platform uses Prometheus to monitor service health and trigger alerts based on the `service_health` metric.

### Alert Rules

| Alert Name | Description | Trigger Condition | Duration | Severity |
|------------|-------------|-------------------|----------|----------|
| ServiceHealthCritical | Service is reporting unhealthy status | service_health == 0 | 60s | critical |
| MultipleServicesUnhealthy | Multiple services are unhealthy | sum(service_health == 0) > 2 | 2m | critical (page) |
| ServiceHealthDegraded | Service is in degraded state | service_health == 0.5 | 5m | warning |

### Example Rules Configuration

```yaml
groups:
  - name: service_health
    rules:
      - alert: ServiceHealthCritical
        expr: service_health == 0
        for: 60s
        labels:
          severity: critical
          team: platform
        annotations:
          summary: "Service {{ $labels.service }} is unhealthy"
          description: "Service {{ $labels.service }} has reported an unhealthy status for more than 1 minute."
```

## Notification Channels

Alerts are sent to the following notification channels:

1. **Slack**
   - Channel: #alfred-alerts
   - Webhook URL: https://hooks.slack.com/services/XXX/YYY/ZZZ
   - Format: Alert name, service, duration, and runbook link

2. **PagerDuty**
   - Only critical alerts with `page: true` label
   - Integration key stored in platform secrets

## Runbooks

Detailed runbooks for addressing alerts are available at:

- [Service Health Critical Runbook](https://internal-docs.alfred.ai/runbooks/service-health.html)
- [Multiple Services Outage Runbook](https://internal-docs.alfred.ai/runbooks/multiple-service-outage.html)
- [Service Degradation Runbook](https://internal-docs.alfred.ai/runbooks/service-degradation.html)

## Dashboards

Service health metrics are visualized in the following Grafana dashboards:

1. [Services Overview Dashboard](https://grafana.alfred.ai/d/services-overview)
2. [Platform Health Dashboard](https://grafana.alfred.ai/d/platform-health)
3. [Health Check Details Dashboard](https://grafana.alfred.ai/d/health-check-details)

## Adding New Alerts

To add a new alert rule:

1. Define the rule in `examples/prometheus/service_health_alerts.yml`
2. Test with Prometheus rule validation:
   ```bash
   promtool check rules service_health_alerts.yml
   ```
3. Add the alert definition to this documentation
4. Create a corresponding runbook if needed
5. Add the rule to the Prometheus configuration

## Silencing Alerts

During maintenance or expected downtime, alerts can be silenced using:

```bash
amtool silence add --comment="Maintenance window" --start=2025-05-15T14:00:00Z --end=2025-05-15T18:00:00Z alertname=~"ServiceHealth.*"
```

For service-specific silences:

```bash
amtool silence add --comment="Service maintenance" --start=2025-05-15T14:00:00Z --end=2025-05-15T16:00:00Z service="ui-admin"
```
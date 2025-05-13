# Prometheus Alert Rules

This directory contains Prometheus alert rules that are loaded by the Prometheus server.

## Alert Rule Files

- `service_health.yml`: Alerts related to service health metrics
  - ServiceUnhealthy: Triggers when a service reports health as 0
  - MultipleServicesUnhealthy: Triggers when multiple services are unhealthy

## Alert Configuration

Alert rules are defined in YAML format and include:

- **Alert name**: A unique identifier for the alert
- **Expression**: The PromQL expression that triggers the alert
- **Duration**: How long the condition must be true before firing
- **Labels**: Used for routing and severity
- **Annotations**: Human-readable information about the alert

## Adding New Alerts

To add a new alert:

1. Create or modify an alert rule file in this directory
2. Ensure it's listed in the `rule_files` section of the main Prometheus configuration
3. Restart Prometheus or send a SIGHUP signal to reload the configuration:
   ```bash
   docker-compose exec prometheus kill -HUP 1
   ```

## Testing Alerts

To test an alert rule without waiting for the real condition:

1. Add a test metric in Prometheus via the API
2. Create a temporary rule that matches this metric
3. Verify the alert fires correctly

## Integration with Alertmanager

These alerts are routed to Alertmanager which handles:

- Grouping similar alerts
- Throttling notifications
- Routing alerts to the appropriate channels (Slack, email, etc.)
- Handling silences and maintenance periods

## Related Documentation

- [Runbooks](../../docs/runbooks/)
- [Grafana Dashboards](../grafana/dashboards/)
- [Alert Routing Configuration](../alertmanager/)
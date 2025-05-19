# Health Check Monitoring Setup

This document explains how to use the health check monitoring features implemented in the Alfred Agent Platform v2.

## Overview

The platform now includes a comprehensive health monitoring system with:

1. **Standardized Health Endpoints**: All services provide `/health`, `/healthz`, and `/metrics` endpoints
2. **Metrics Collection**: Prometheus scrapes metrics from all services
3. **Visualization**: Grafana dashboards display service health status
4. **Dependency Tracking**: Services report their dependencies' health

## Accessing Monitoring Dashboards

### Prometheus UI

The Prometheus UI is available at [http://localhost:9090](http://localhost:9090)

Key queries to try:

- `service_health`: Shows health status of all services
- `up`: Shows which targets Prometheus can reach
- `service_health == 0`: Shows unhealthy services

### Grafana Dashboards

Grafana is available at [http://localhost:3005](http://localhost:3005)

Default credentials:
- Username: `admin`
- Password: `admin` (or the value of `MONITORING_ADMIN_PASSWORD` environment variable)

Available dashboards:
- **Alfred Platform Service Health**: Shows health status of all services

## Checking Health Status from CLI

You can quickly check the health status of services using:

```bash
# Check specific service health
curl -s http://localhost:8011/health | jq  # agent-core
curl -s http://localhost:8079/health | jq  # model-registry
curl -s http://localhost:8080/health | jq  # model-router

# Run comprehensive health check
./scripts/healthcheck/validate-all-healthchecks.sh
```

## Understanding Health Response Format

A service health response follows this format:

```json
{
  "status": "ok",           // "ok", "degraded", or "error"
  "version": "1.0.0",       // Service version
  "services": {             // Dependencies
    "database": "ok",       // Each dependency with its status
    "cache": "ok",
    "model_registry": "ok"
  }
}
```

Status meanings:
- **ok**: Service is fully operational
- **degraded**: Service is operating but with reduced functionality
- **error**: Service is not operational

## Adding Custom Alerts

You can add custom alerts in Prometheus by editing:
`monitoring/prometheus/rules/service_health.yml`

Example alert rule:

```yaml
groups:
- name: service_health_alerts
  rules:
  - alert: ServiceDown
    expr: service_health == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Service {{ $labels.instance }} is down"
      description: "Service {{ $labels.instance }} has been reporting unhealthy for more than 1 minute."
```

## Troubleshooting Health Checks

If a service is reporting as unhealthy:

1. **Check Container Logs**:
   ```bash
   docker logs <service-name>
   ```

2. **Verify Connectivity**:
   ```bash
   # Check if you can reach the service
   curl -v http://localhost:<port>/health
   ```

3. **Check Dependencies**:
   ```bash
   # Look at the health response to see which dependency is failing
   curl -s http://localhost:<port>/health | jq
   ```

4. **Verify Prometheus Target**:
   - Open [http://localhost:9090/targets](http://localhost:9090/targets)
   - Check if the service is being scraped correctly

## Adding a New Service to Monitoring

When adding a new service:

1. **Implement Health Endpoints**: Follow the [Health Check Integration Guide](../HEALTH_CHECK_INTEGRATION_GUIDE.md)

2. **Update Prometheus Configuration**:
   ```bash
   ./scripts/healthcheck/update-prometheus-config.sh
   ```

3. **Restart Prometheus**:
   ```bash
   docker-compose restart monitoring-metrics
   ```

4. **Verify Monitoring**:
   - Check Prometheus targets
   - Verify service appears in Grafana dashboard

## Health Check Maintenance

To ensure health checks remain effective:

1. **Regular Testing**: Run the validation script periodically
   ```bash
   ./scripts/healthcheck/validate-all-healthchecks.sh
   ```

2. **Keep Dependencies Updated**: Ensure dependency tracking is accurate

3. **Review Alerts**: Regularly review alert rules and thresholds

4. **Update Documentation**: Keep documentation updated with any changes to health check implementation

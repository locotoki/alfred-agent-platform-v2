# Metrics Exporter Upgrade Guide

This document describes the Phase 1 metrics exporter implementation (v0.2.0-phase1), including the upgrade to healthcheck binary v0.4.0 and the integration with Prometheus and Grafana for enhanced monitoring capabilities.

## Overview

The Phase 1 metrics exporter implementation includes the following key changes:

1. **Upgraded healthcheck binary to v0.4.0** across all key services
2. **Added metrics port exposure (9091)** for all services
3. **Configured healthcheck binary to export Prometheus metrics** with the `--export-prom` flag
4. **Enhanced Prometheus configuration** to collect service_health metrics
5. **Updated Grafana dashboard** to visualize service_health metrics
6. **Tightened health check timings** for different service classes

## Implementation Details

### 1. Upgraded Healthcheck Binary

All key services now use the healthcheck binary v0.4.0 from `ghcr.io/alfred/healthcheck:0.4.0`. The binary is copied into the container during build and is used for both health checking and metrics exporting.

Example Dockerfile change:

```dockerfile
FROM ghcr.io/alfred/healthcheck:0.4.0 AS healthcheck

FROM python:3.11-slim

# ... other instructions ...

# Copy healthcheck binary
COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck

# ... other instructions ...

# Expose application port
EXPOSE 8501
# Expose metrics port for Prometheus
EXPOSE 9091

# Run the application with healthcheck metrics exporter
CMD ["bash", "-c", "healthcheck serve --export-prom :9091 & exec uvicorn app.main:app --host 0.0.0.0 --port 8501"]
```

### 2. Prometheus Configuration

Added a new job configuration in Prometheus to scrape the service_health metrics from all services:

```yaml
# New job for service health metrics from v0.4.0 healthcheck binary
- job_name: 'service_health'
  static_configs:
    - targets: ['alfred-bot:9091', 'architect-api:9091', 'financial-tax:9091', 'legal-compliance:9091', 'agent-rag:9091', 'agent-atlas:9091']
  metrics_path: '/metrics'
```

### 3. Grafana Dashboard Updates

The Platform Health Dashboard has been enhanced with new panels to visualize the service_health metrics:

- Added "Detailed Service Health (v0.4.0)" panel showing service health status from the metrics exporter
- Added "Detailed Health by Service" panel showing service health percentages by service name

### 4. Health Check Timings

Tightened health check timings for different service classes to improve monitoring responsiveness:

```yaml
# Common health check settings - updated for v0.4.0 with tighter timings
x-critical-health-check: &critical-health-check
  interval: 15s
  timeout: 10s
  retries: 3
  start_period: 30s

x-basic-health-check: &basic-health-check
  interval: 30s
  timeout: 20s
  retries: 5
  start_period: 45s

x-database-health-check: &database-health-check
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s

x-ui-health-check: &ui-health-check
  interval: 30s
  timeout: 15s
  retries: 3
  start_period: 60s
```

## Services Updated

The following services have been updated with the new healthcheck binary and metrics exporter:

1. `services/rag-service`
2. `services/financial-tax`
3. `services/legal-compliance`
4. `services/architect-api`
5. `services/alfred-bot`
6. `rag-gateway`

## How to Apply the Changes

To apply these changes, run the update script:

```bash
cd /home/locotoki/projects/alfred-agent-platform-v2
./scripts/update-healthcheck-binary.sh
```

Then rebuild and restart the affected services:

```bash
docker-compose -f docker-compose-clean.yml build services/rag-service services/financial-tax services/legal-compliance services/architect-api services/alfred-bot rag-gateway
docker-compose -f docker-compose-clean.yml up -d
```

## Verifying the Changes

1. Check that the metrics endpoints are accessible:

```bash
curl http://localhost:9091/metrics
curl http://localhost:9092/metrics  # For agent-rag
curl http://localhost:9093/metrics  # For agent-atlas
curl http://localhost:9094/metrics  # For agent-social
curl http://localhost:9095/metrics  # For agent-financial
curl http://localhost:9096/metrics  # For agent-legal
```

2. Verify the updated Grafana dashboard at http://localhost:3005
   - Log in with admin/admin (or your configured password)
   - Navigate to the "Platform Health Dashboard"
   - Check that the new "Detailed Service Health (v0.4.0)" panel is showing data

## Next Steps

- [ ] Implement Phase 2 metrics exporter features (detailed service-specific metrics)
- [ ] Add alerting rules for service health status
- [ ] Extend metrics collection to include custom application metrics
- [ ] Optimize metrics storage and retention policies

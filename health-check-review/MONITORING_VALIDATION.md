# Monitoring Validation Guide

This document outlines how to validate the monitoring stack (Prometheus and Grafana) in the Alfred Agent Platform v2.

## Overview

The monitoring validation ensures that Prometheus and Grafana are properly configured and healthy. This validation is critical for ensuring that the health check metrics are being collected and visualized correctly.

## Validation Script

The `validate-monitoring.sh` script performs several health checks against the monitoring services:

```bash
./scripts/validate-monitoring.sh
```

### Script Behavior

The script performs the following checks:

1. **Prometheus Health Check**
   - Calls `/-/healthy` endpoint
   - Verifies the response contains "Healthy"
   - Fails if the endpoint is unreachable or returns an unexpected response

2. **Prometheus Ready Check**
   - Calls `/-/ready` endpoint
   - Verifies the response contains "Ready"
   - Fails if the endpoint is unreachable or returns an unexpected response

3. **Grafana Health Check**
   - Calls `/api/health` endpoint with admin credentials
   - Verifies the database reports as "ok"
   - Fails if the endpoint is unreachable or returns an unexpected status

The script uses the following environment variables:
- `GF_SECURITY_ADMIN_PASSWORD`: Grafana admin password (defaults to "admin")

### Integration Points

The monitoring validation is integrated into:

1. **Makefile**
   ```makefile
   .PHONY: phase0
   phase0:
       docker-compose -f docker-compose-clean.yml build
       ./start-platform.sh -a start -e dev
       sleep 120
       ./scripts/verify-service-health.sh
       ./scripts/validate-monitoring.sh  # Monitoring validation
       ./start-platform.sh -a stop -e dev
   ```

2. **CI Pipeline**
   ```yaml
   - name: Validate monitoring
     run: ./scripts/validate-monitoring.sh
   ```

## Manual Validation

In addition to the automated script, you can manually verify the monitoring services:

### Prometheus

1. Access the Prometheus UI at `http://localhost:9090`
2. Check the status page: `http://localhost:9090/status`
3. Verify targets are being scraped: `http://localhost:9090/targets`
4. Verify service discovery: `http://localhost:9090/service-discovery`

### Grafana

1. Access the Grafana UI at `http://localhost:3005`
2. Log in with the admin credentials
3. Navigate to Configuration > Data Sources to verify Prometheus is connected
4. View the platform health dashboard to verify metrics are being displayed

## Troubleshooting

If the validation script fails, check the following:

### Prometheus Issues
- Verify Prometheus container is running: `docker ps | grep prometheus`
- Check Prometheus logs: `docker logs <prometheus-container-id>`
- Verify Prometheus configuration: `/etc/prometheus/prometheus.yml` within the container

### Grafana Issues
- Verify Grafana container is running: `docker ps | grep grafana`
- Check Grafana logs: `docker logs <grafana-container-id>`
- Verify Grafana can connect to Prometheus
- Check dashboard provisioning status

## Extending the Validation

The current validation script can be extended to cover additional monitoring aspects:

1. **Alert Manager Validation**
   - Add checks for Alert Manager health endpoints
   - Verify alert rules are loaded correctly

2. **Dashboard Validation**
   - Verify specific dashboards are provisioned
   - Check for key panels and visualizations

3. **Metric Validation**
   - Verify specific metrics are being collected
   - Validate metric values against expected ranges
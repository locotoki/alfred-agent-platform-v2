# Grafana Health Implementation

This document describes the implementation of health checks for Grafana instances in the Alfred Agent Platform v2.

## Overview

The Grafana health probe provides a three-state health check for Grafana instances:

- **OK**: Grafana is fully operational and all datasources are healthy
- **DEGRADED**: Grafana core is running but one or more datasources are experiencing issues
- **ERROR**: Grafana is down or unreachable

## Implementation Details

### Health Check Logic

The Grafana health checker performs the following checks:

1. Core API check: `/api/health` endpoint to verify Grafana's core functionality
2. Datasource health check: Iterates through all defined datasources and checks their health status
3. Metrics collection: Captures performance metrics and datasource availability

### CLI Usage

```
grafana-probe --grafana http://grafana:3000 [--grafana-auth user:pass] [--timeout 10] [--verbose]
```

Options:
- `--grafana`: Grafana instance URL (required)
- `--grafana-auth`: Authentication in format `user:pass` (basic auth) or `user:token` (API token)
- `--timeout`: Request timeout in seconds (default: 10)
- `--verbose`: Enable detailed output

### Exit Codes

- **0**: Grafana is healthy (OK)
- **1**: Grafana is degraded (some datasources are down)
- **2**: Grafana is unhealthy (server error or unreachable)
- **3**: Unknown status

### Metrics

The probe collects and exports the following Prometheus metrics:

1. `grafana_datasource_up_total{type}`: Gauge that tracks the number of datasources by type that are up (1) or down (0)
2. `grafana_api_latency_seconds`: Histogram that measures the latency of Grafana API requests with buckets ranging from 0.25s to 4s

### Authentication

The probe supports two authentication methods:

- **Basic Auth**: Provide credentials in the format `user:pass`
- **API Token**: Provide token in the format `user:token`

## Integration

### Docker Compose

Add this to your monitoring docker-compose file:

```yaml
services:
  grafana-health:
    image: ${REGISTRY:-local}/grafana-probe:latest
    command: ["--grafana", "http://grafana:3000", "--timeout", "5"]
    restart: unless-stopped
    depends_on:
      - grafana
    healthcheck:
      test: ["CMD", "/bin/grafana-probe", "--grafana", "http://grafana:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
```

### Kubernetes

```yaml
livenessProbe:
  exec:
    command:
      - "/bin/grafana-probe"
      - "--grafana"
      - "http://grafana:3000"
  initialDelaySeconds: 60
  periodSeconds: 30
  timeoutSeconds: 10
  failureThreshold: 3
```

## Local Testing

You can test the Grafana health probe locally with Docker:

```bash
# Start a local Grafana instance
docker run -d --name grafana -p 3000:3000 grafana/grafana:10.4.3

# Build and run the health probe
go build -o bin/grafana-probe cmd/grafana-probe/main.go
bin/grafana-probe --grafana http://localhost:3000 --verbose
```

## Alert Rules

The implementation includes Prometheus alert rules for Grafana health:

1. **GrafanaDown**: Critical alert if Grafana is down for more than 1 minute
2. **GrafanaDegraded**: Warning alert if Grafana is in a degraded state for more than 5 minutes
3. **GrafanaDatasourceDown**: Warning alert if a specific datasource is down for more than 5 minutes
4. **GrafanaApiLatencyHigh**: Warning if the 95th percentile of API latency exceeds 2 seconds for 10 minutes

These rules are defined in `monitoring/prometheus/alerts/grafana_health.yml`.
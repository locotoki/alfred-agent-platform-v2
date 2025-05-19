# Prometheus Health Check Implementation Plan

This document outlines a standardized approach for implementing Prometheus health checks across all services in the Alfred Agent Platform v2.

## Overview

We will implement a consistent health check and metrics export pattern for all services, following the established health check standards documented in `/docs/HEALTH_CHECK_STANDARD.md`. This plan builds on the existing implementation while ensuring consistency across all service types.

## Goals

1. Standardize health check implementation across all services
2. Consolidate metrics exposure on port 9091 for all services
3. Implement consistent metrics for service health status
4. Ensure all services use the healthcheck binary v0.4.0 or health module
5. Configure Prometheus to properly scrape all service metrics
6. Set up appropriate alerting rules for service health

## Implementation Approach

### 1. Service Health Check Requirements

All services must implement three standardized endpoints:

- **`/health`**: Detailed health status in JSON format
  - Example response: `{"status": "ok|degraded|error", "version": "1.0.0", "services": {...}}`
- **`/healthz`**: Simple health probe for container orchestration
  - Example response: `{"status": "ok"}`
- **`/metrics`**: Prometheus metrics in exposition format
  - Must be exposed on port 9091
  - Must include standard metrics:
    - `service_health` (gauge, 1=healthy, 0=unhealthy)
    - `service_requests_total` (counter, request count)
    - `service_info{name="...",version="..."} 1` (gauge with service metadata)

### 2. Implementation Patterns by Service Type

#### Python/FastAPI Services

Use the centralized health module:

```python
from libs.agent_core.health import create_health_app

# Create the health app
health_app = create_health_app(service_name="my-service", version="1.0.0")

# Register dependencies to track
health_app.register_dependency("database", "ok")
health_app.register_dependency("redis", "ok")
health_app.register_dependency("pubsub", "ok")

# Update dependency status as needed
health_app.update_dependency_status("database", "error")  # When DB connection fails
```

Mount the health app in your main FastAPI application:

```python
from fastapi import FastAPI

app = FastAPI()
app.mount("/health", health_app)
```

#### Node.js/Express Services

Use the health module pattern:

```javascript
const express = require('express');
const { router: healthRouter, createMetricsServer } = require('./health');

const app = express();

// Mount health router
app.use('/', healthRouter);

// Start the main server
app.listen(3000, () => {
  console.log('Main server listening on port 3000');
});

// Start metrics server on port 9091
createMetricsServer(9091);
```

#### Docker Container Health Checks

All services should use the healthcheck binary wrapper:

```dockerfile
FROM ghcr.io/alfred/healthcheck:0.4.0 AS healthcheck

FROM python:3.11-slim
# ... other instructions

# Copy healthcheck binary
COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck

# ... other instructions

# Expose metrics port
EXPOSE 9091

# Run with healthcheck wrapper
CMD ["bash", "-c", "healthcheck serve --export-prom :9091 -- exec python -m app.main"]
```

### 3. Prometheus Configuration Updates

Update Prometheus configuration to include all services:

```yaml
# Unified service health scraping configuration
- job_name: 'service_health'
  static_configs:
    - targets: [
        'agent-core:9091',
        'agent-rag:9091',
        'agent-atlas:9091',
        'agent-social:9091',
        'agent-financial:9091',
        'agent-legal:9091',
        'model-registry:9091',
        'model-router:9091',
        'ui-chat:9091',
        'ui-admin:9091',
        'db-metrics:9091',
        'redis-exporter:9091'
      ]
  metrics_path: '/metrics'
```

### 4. Standardized Alert Rules

Configure alert rules for service health:

```yaml
groups:
- name: service_alerts
  rules:
  - alert: ServiceDown
    expr: service_health == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Service {{ $labels.job }} is down"
      description: "Service {{ $labels.job }} health check is failing for more than 1 minute"

  - alert: ServiceDegraded
    expr: service_health{status="degraded"} == 1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Service {{ $labels.job }} is degraded"
      description: "Service {{ $labels.job }} is in degraded state for more than 5 minutes"
```

## Implementation Plan

### Phase 1: Preparation

1. Audit current health check implementation across all services
2. Update health check binary to v0.4.0 where needed
3. Test metrics export on port 9091 for a sample service

### Phase 2: Core Services Implementation

1. Update Python-based agent services
   - agent-core, agent-rag, agent-social, agent-financial, agent-legal
2. Update Node.js-based services
   - ui-admin, mission-control-simplified

### Phase 3: Infrastructure Services Implementation

1. Update LLM infrastructure services
   - model-registry, model-router
2. Update DB services
   - Create custom metrics exporters for database services

### Phase 4: Prometheus Configuration

1. Update Prometheus scraping configuration
2. Set up alert rules
3. Test metrics collection from all services

### Phase 5: Grafana Dashboard

1. Create consolidated service health dashboard
2. Add service-specific metrics panels
3. Configure health status alerts

## Validation Criteria

A service is considered compliant with the health check standard when it:

1. Exposes `/health`, `/healthz`, and `/metrics` endpoints
2. Reports metrics on port 9091
3. Includes standard metrics (service_health, service_requests_total)
4. Is properly scraped by Prometheus
5. Appears in the Grafana dashboard

## Implementation Scripts

1. `audit-health-implementation.sh`: Check services for health check compliance
2. `update-healthcheck-binary.sh`: Update to latest healthcheck binary
3. `standardize-service-health.sh`: Apply standard health check pattern
4. `update-prometheus-config.sh`: Update Prometheus configuration

## Next Steps After Implementation

1. Add custom metrics for service-specific monitoring
2. Implement advanced health checks for specific service types
3. Set up more sophisticated alerting based on service dependencies
4. Create runbooks for common health check failures

# Health Checks Implementation Guide

This document serves as the primary reference for health check implementation in the Alfred Agent Platform v2.

## Overview

The platform implements standardized health checks across all services following industry best practices:

1. **Standard Endpoints**:
   - `/health` - Detailed health information
   - `/healthz` - Simple readiness probe
   - `/metrics` - Prometheus metrics

2. **Port Separation**:
   - Application port: Main service interface
   - Metrics port: Dedicated for Prometheus metrics (909x)

3. **Health Check Integration**:
   - Docker container health checks
   - Prometheus monitoring
   - Grafana dashboards
   - Alerting

## Implementation Status

All services now implement standardized health checks with the following compliance levels:

| Service | /health | /healthz | /metrics | Container Health |
|---------|:-------:|:--------:|:--------:|:----------------:|
| agent-core | ✅ | ✅ | ✅ | ✅ |
| agent-social | ✅ | ✅ | ✅ | ✅ |
| agent-financial | ✅ | ✅ | ✅ | ✅ |
| agent-legal | ✅ | ✅ | ✅ | ✅ |
| db-postgres | ✅ | ✅ | ✅ | ✅ |
| db-storage | ✅ | ✅ | ✅ | ✅ |
| redis | ✅ | ✅ | ✅ | ✅ |
| ui-admin | ✅ | ✅ | ✅ | ✅ |

## Using Health Checks

### Command Line Verification

```bash
# Check service health
curl http://localhost:8011/health

# Simple health probe
curl http://localhost:8011/healthz

# Metrics endpoint
curl http://localhost:9091/metrics
```

### Dashboard Access

The health status of all services can be monitored through Grafana:

- URL: http://localhost:3005
- Dashboard: Platform Health Dashboard
- Username: admin
- Password: admin

## Documentation

For more detailed information about health check implementation, see:

- [/docs/operations/containerization/docker-compose-health-checks.md](./docs/operations/containerization/docker-compose-health-checks.md) - Comprehensive health check guide
- [/docs/HEALTH_CHECK_STANDARD.md](./docs/HEALTH_CHECK_STANDARD.md) - Health check standards definition

## Historical Documentation

Previous health check implementation documents have been archived in:
- [/docs/archive/health-checks/](./docs/archive/health-checks/)

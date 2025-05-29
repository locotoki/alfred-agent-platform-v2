# Health Check Next Steps

This document outlines the next steps for improving health checks across all services in the Alfred Agent Platform v2.

## Current Status

- Redis and PubSub services: Health checks implemented and working correctly
- Prometheus configuration: Updated to collect metrics from all services
- Other services: Using inconsistent health check methods, many showing as unhealthy

## Key Issues Identified

1. **Inconsistent health check commands**:
   - Some services use `healthcheck` binary which is not available
   - Some services use `curl` directly which is more reliable

2. **Missing health endpoints**:
   - Not all services implement standardized `/health`, `/healthz`, and `/metrics` endpoints
   - Inconsistent response formats between services

3. **Container health status**:
   - Most containers show as "unhealthy" which makes monitoring difficult
   - This affects dependency tracking for service startup

## Proposed Actions

### Phase 1: Immediate Fixes (Completed)

- ✅ Fixed Redis and PubSub health checks
- ✅ Updated Prometheus configuration for metrics collection
- ✅ Created documentation for health check implementation

### Phase 2: Standardize Docker Compose Health Checks

1. Update all `healthcheck` commands in `docker-compose.yml` to use `curl`:
   ```yaml
   healthcheck:
     test: ["CMD", "curl", "-f", "http://localhost:<PORT>/health"]
     interval: 30s
     timeout: 20s
     retries: 5
     start_period: 45s
   ```

2. Test each service to ensure the health endpoints are properly implemented:
   - `/health` for detailed health info
   - `/healthz` for simple health probe
   - `/metrics` for Prometheus metrics

3. Create a PR for these changes with a clear rollback plan in case of issues.

### Phase 3: Implement Standard Health Endpoints for All Services

1. Identify services lacking standard health endpoints

2. For each service, implement:
   ```
   /health  - Detailed health status with dependencies
   /healthz - Simple health probe
   /metrics - Prometheus metrics
   ```

3. Update Dockerfiles to standardize health check commands

4. Create a PR for each service or group of related services

### Phase 4: Monitoring Improvements

1. Create Grafana dashboards for service health visualization

2. Add alerting rules for degraded/unhealthy services

3. Implement auto-recovery for common failure modes

## Timeline

- Phase 2: 1-2 days
- Phase 3: 3-5 days (depending on number of services)
- Phase 4: 2-3 days

## Expected Benefits

- All services will report health status in a consistent format
- System health will be more visible and actionable
- Service dependencies will be tracked more accurately
- Prometheus metrics will provide detailed health insights
- Reduced downtime through faster issue detection

## Execution Plan

1. Create a branch for Phase 2 changes
2. Update all health check commands in `docker-compose.yml`
3. Test locally before creating PR
4. After Phase 2 is merged, proceed with Phase 3 by service group
5. Complete Phase 4 after all services are reporting healthy status

## Risks and Mitigation

- Risk: Service health checks might fail differently
  - Mitigation: Test each service individually before PR

- Risk: Health check failures might prevent service startup
  - Mitigation: Implement with longer start_period for initial deployment

- Risk: Too many changes at once might be difficult to debug
  - Mitigation: Implement changes in phases with careful testing

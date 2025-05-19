# Phase 5: Database and Infrastructure Services Health Check Implementation Plan

## Overview
Phase 5 is the final phase of our health check standardization project. In this phase, we will implement health checks for the remaining 12 services, focusing on database services, infrastructure services, and monitoring services.

## Implementation Status
- **Current Progress**: 64.7% (22/34 services)
- **Phase 5 Target**: 100% (34/34 services)

## Services to Implement

### Database Services
1. db-api
   - Current status: Unhealthy
   - Health endpoints available but not Dockerfile
   - Metrics port not exposed

2. db-admin
   - Current status: Unhealthy
   - Health endpoints available but not Dockerfile
   - Metrics port not exposed

3. db-realtime
   - Current status: Unhealthy
   - Health endpoints available but not Dockerfile
   - Metrics port not exposed

### Infrastructure Services
4. vector-db
   - Current status: Unhealthy
   - Health endpoints available but not Dockerfile
   - Metrics port not exposed

5. mail-server
   - Current status: Unhealthy
   - Health endpoints available but not Dockerfile
   - Metrics port not exposed

### Monitoring Services
6. monitoring-db
   - Current status: Unhealthy
   - Health endpoints available but not Dockerfile
   - Metrics port not exposed

7. monitoring-node
   - Current status: Unhealthy
   - Health endpoints available but not Dockerfile
   - Metrics port not exposed

8. monitoring-redis
   - Current status: Unhealthy
   - Health endpoints available but not Dockerfile
   - Metrics port not exposed

9. redis-exporter
   - Current status: Unhealthy
   - Health endpoints available but not Dockerfile
   - Metrics port not exposed

10-11. monitoring-dashboard, monitoring-metrics
   - Current status: No health check
   - Need to determine if health checks should be implemented

## Implementation Approach

Each service will follow the standard health check pattern from our documentation:

```dockerfile
FROM alfred/healthcheck:0.4.0 AS healthcheck

FROM <base-image>
COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck
RUN chmod +x /usr/local/bin/healthcheck

# Service-specific content...

# Expose ports
EXPOSE <app-port>
EXPOSE 9091

# Run with healthcheck wrapper
CMD ["healthcheck", "--export-prom", ":9091", "--", "<command>", "<args>"]
```

## Docker Compose Configuration

Each service needs the following in docker-compose.yml:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:<PORT>/health"]
  <<: *basic-health-check
ports:
  - "<host-port>:<app-port>"
  - "<metrics-host-port>:9091"
labels:
  <<: *service-labels
  prometheus.metrics.port: "9091"
```

## Prometheus Alert Rules

After all services have been implemented, we will create alert rules for `service_health` in Prometheus:

```yaml
- alert: ServiceHealthCritical
  expr: service_health == 0
  for: 60s
  labels:
    severity: critical
  annotations:
    summary: "Service {{ $labels.service }} is unhealthy"
    description: "Service has reported an unhealthy status for more than 1 minute"
```

## Timeline

1. Week 1 (May 15-22): Fix and test database services
2. Week 2 (May 22-29): Fix and test infrastructure services
3. Week 3 (May 29-June 5): Fix and test monitoring services
4. Week 4 (June 5-12): Clean up legacy health checks and implement alert rules

## Testing Strategy

Each service will be tested by:
1. Building the service with the new Dockerfile
2. Verifying the health endpoints return proper responses
3. Confirming metrics are exposed on port 9091
4. Validating Prometheus can scrape the metrics

## Final Deliverables

1. Standardized health checks for all services
2. Prometheus alert rules for service health
3. Updated documentation:
   - HEALTH_CHECK_IMPLEMENTATION_STATUS.md
   - PHASE5-COMPLETION-REPORT.md
   - Alert rule documentation
4. Dependabot setup for alfred/healthcheck image updates
5. Removal of legacy shell probes repository-wide

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Database services may require special considerations | Test in isolation, ensure proper shutdown sequences |
| Some services may not be compatible with the standard pattern | Create custom health check solutions as needed |
| Prometheus alerts may create noise | Start with longer thresholds, adjust based on false positives |

## Success Criteria

- All 34 services are using the standardized health check pattern
- All services expose metrics on port 9091
- All services include the service_health gauge metric
- Prometheus can scrape metrics from all services
- Alert rules are in place for service_health
- No legacy shell probes remain in the codebase

## Team and Resources

- Lead implementer: [Your Name]
- Reviewers: [Reviewer Names]
- Required resources:
  - Test environment with full platform deployment
  - Access to Prometheus and Grafana for metrics validation

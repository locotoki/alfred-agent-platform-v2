# Phase 5: Database and Infrastructure Services Health Check Implementation

This document outlines the scaffold for Phase 5 implementation, which will focus on the remaining 12 services.

## Services to Implement

### Database Services
- db-api
- db-admin
- db-realtime

### Infrastructure Services
- vector-db
- mail-server

### Monitoring Services
- monitoring-db
- monitoring-node
- monitoring-redis
- redis-exporter

## Approach for Each Service

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

Implement alert rules for `service_health` in Prometheus:

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

1. Week 1: Fix and test database services
2. Week 2: Fix and test infrastructure services
3. Week 3: Fix and test monitoring services
4. Week 4: Clean up legacy health checks and implement alert rules

## Testing Strategy

Each service will be tested by:
1. Building the service with the new Dockerfile
2. Verifying the health endpoints return proper responses
3. Confirming metrics are exposed on port 9091
4. Validating Prometheus can scrape the metrics

## Documentation Updates

- Update HEALTH_CHECK_IMPLEMENTATION_STATUS.md
- Create PHASE5-COMPLETION-REPORT.md
- Update README.md with new health check information
- Document alert rules in monitoring/README.md

This scaffold will serve as a starting point for Phase 5 implementation.

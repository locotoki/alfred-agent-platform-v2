# Health Check Standardization Tools

This directory contains tools for standardizing health checks across all services using the
healthcheck binary v0.4.0.

## Tools

1. **audit-health-binary.sh**: Lists all Dockerfiles that still use legacy health check methods (< v0.4.0)
2. **bulk-update-health-binary.sh**: Updates Dockerfiles to use healthcheck binary v0.4.0
3. **ensure-metrics-exported.sh**: Verifies services are properly exporting metrics
4. **fix-health-endpoints.sh**: Adds standardized health endpoints to services
5. **run-full-healthcheck.sh**: Executes a full health check across all services
6. **update-prometheus-config.sh**: Updates Prometheus configuration to scrape metrics from all services

## Usage

### Auditing Legacy Health Checks

```bash
./scripts/healthcheck/audit-health-binary.sh
```

This will list all Dockerfiles that are still using legacy health check methods.

### Updating Dockerfiles

```bash
./scripts/healthcheck/bulk-update-health-binary.sh
```

This will:
- Update all Dockerfiles to use healthcheck binary v0.4.0
- Add EXPOSE 9091 directive for metrics port
- Update healthcheck commands to export Prometheus metrics

### Fixing Health Endpoints

```bash
./scripts/healthcheck/fix-health-endpoints.sh
```

This script:
- Updates health endpoint implementations to the standard format
- Adds wrappers for services that don't support HTTP endpoints natively (Redis, PubSub)
- Standardizes the response format for health checks

### Verifying Metrics Export

```bash
./scripts/healthcheck/ensure-metrics-exported.sh
```

This enhanced script:
- Checks all running services to ensure they are properly exporting metrics on port 9091
- Verifies Docker Compose configuration for prometheus.metrics.port labels
- Examines Dockerfiles to confirm they include the healthcheck binary and expose port 9091
- Checks if Prometheus is configured to scrape metrics endpoints
- Provides a comprehensive report with fix suggestions for any issues found

### Running Full Health Check

```bash
./scripts/healthcheck/run-full-healthcheck.sh
```

Performs a comprehensive health check of all services and reports status.

### Updating Prometheus Configuration

```bash
./scripts/healthcheck/update-prometheus-config.sh
```

This script:
- Scans Docker Compose files to find services exposing port 9091 (metrics port)
- Updates the Prometheus configuration with all discovered services
- Creates a unified job that collects metrics from all services
- Maintains backwards compatibility with existing specialized jobs
- Validates the configuration before applying changes

## Standardization Process

The complete health check standardization process is:

1. Audit all services for legacy health checks using `audit-health-binary.sh`
2. Update Dockerfiles to use healthcheck binary v0.4.0 using `bulk-update-health-binary.sh`
3. Fix health endpoints for non-HTTP services using `fix-health-endpoints.sh`
4. Update Prometheus configuration to scrape metrics using `update-prometheus-config.sh`
5. Verify metrics export is working correctly using `ensure-metrics-exported.sh`
6. Run full health check to validate implementation using `run-full-healthcheck.sh`
7. Tag the release using `../tag-healthcheck-release.sh`

## Service Health Implementation

The standardized health check implementation provides:

- **Consistent endpoints**:
  - `/health` - Detailed service health with dependency information
  - `/healthz` - Simple health probe for kubernetes/docker
  - `/metrics` - Prometheus metrics

- **Standard response format**:
  ```json
  {
    "status": "healthy|unhealthy|degraded",
    "version": "1.0.0",
    "services": {
      "dependency1": "healthy|unhealthy|degraded",
      "dependency2": "healthy|unhealthy|degraded"
    }
  }
  ```

- **Metrics port**: All services expose metrics on port 9091

## Benefits

- Consistent health check implementation across all services
- Unified metrics collection on port 9091
- Standardized service_health metrics for monitoring
- Better observability of service health status
- Automatic detection of new services in Prometheus
- Smart dependency tracking for troubleshooting
- Circuit breaker patterns for graceful degradation
# Prometheus Health Check Implementation

This document outlines the implementation of the Prometheus health check probe for the Alfred Agent Platform v2 as part of Phase 5 health check standardization.

## Overview

The Prometheus health check probe is a specialized binary that can:

1. Verify the health of a Prometheus instance by querying its API
2. Report health status in three states: OK, DEGRADED, or ERROR
3. Provide Prometheus metrics about the health status
4. Be used in Docker containers as part of the standard healthcheck pattern

## Implementation Details

### Command-line Interface

The Prometheus health probe accepts the following command-line flags:

```
--prometheus            Enable Prometheus health check
--prometheus-url URL    Prometheus API endpoint to probe (default: http://localhost:9090/api/v1/query?query=up)
--timeout N             Request timeout in seconds (default: 10)
--verbose               Enable verbose output
--help                  Show help message
```

### Health Status Reporting

The probe reports health in three states:

1. **OK (Exit Code 0)**: Prometheus is healthy and all monitored targets are up
2. **DEGRADED (Exit Code 1)**: Prometheus is running but some targets are down
3. **ERROR (Exit Code 2)**: Prometheus is not responding or has critical issues

### Metrics Provided

The probe exposes the following metrics when used with the metrics exporter:

```
# HELP prometheus_health_status Health status of the Prometheus instance (0=error, 1=degraded, 2=ok)
# TYPE prometheus_health_status gauge
prometheus_health_status 2
```

## Integration with Healthcheck Binary

The Prometheus health probe is integrated with the existing healthcheck binary:

```bash
# Check a Prometheus instance
healthcheck --prometheus --prometheus-url http://prometheus:9090/api/v1/query?query=up

# Check and expose metrics
healthcheck --prometheus --export-prom :9091 --prometheus-url http://prometheus:9090/api/v1/query?query=up
```

## Alert Rules

The implementation includes pre-configured alert rules in `monitoring/prometheus/alerts/prometheus_health.yml`:

1. **PrometheusDown**: Critical alert when a Prometheus instance is reporting ERROR status (fires after 1 minute)
2. **PrometheusDegraded**: Warning alert when a Prometheus instance is reporting DEGRADED status (fires after 5 minutes)
3. **PrometheusTargetsDown**: Warning alert when specific targets are down
4. **PrometheusScrapeFailures**: Warning alert when Prometheus is experiencing scrape failures
5. **PrometheusRuleEvaluationFailures**: Warning alert when Prometheus has rule evaluation failures

## Testing

The implementation includes both unit tests and integration tests:

1. **Unit Tests**: Testing the core health check logic with mocked Prometheus API responses
2. **Integration Tests**: Testing the actual binary with a mock Prometheus server

Run tests with:
```bash
# Unit tests
go test -v ./internal/prometheus

# Integration tests
RUN_INTEGRATION_TESTS=1 go test -v ./tests/prometheus -tags=integration
```

## Docker Configuration

A specialized Dockerfile is provided to build a container with the Prometheus health probe:

```dockerfile
FROM alfred/healthcheck:prometheus-probe

# Service configuration...

HEALTHCHECK --interval=30s --timeout=20s --retries=3 \
    CMD ["prometheus-probe", "--prometheus", "--prometheus-url", "http://prometheus:9090/api/v1/query?query=up"]

# Run command...
```

## Deployment Recommendations

1. **High Availability Configurations**:
   For HA Prometheus setups, configure the health probe with multiple Prometheus instances:
   ```bash
   # Primary Prometheus
   prometheus-probe --prometheus --prometheus-url http://prometheus-1:9090/api/v1/query?query=up

   # Secondary Prometheus (if primary fails)
   prometheus-probe --prometheus --prometheus-url http://prometheus-2:9090/api/v1/query?query=up
   ```

2. **Monitoring Dashboard Integration**:
   The `prometheus_health_status` metric can be added to Grafana dashboards to provide visibility into the health of your Prometheus instances.

3. **Containerized Services**:
   Add the Prometheus health probe to existing services by updating the Docker HEALTHCHECK directive to include both service health and Prometheus health.

## Troubleshooting

If you encounter issues with the Prometheus health probe:

1. **API Connection Failures**:
   - Verify network connectivity to the Prometheus instance
   - Check if Prometheus is running and accessible
   - Ensure proper authentication/authorization if required

2. **Unexpected Health Status**:
   - Use the `--verbose` flag to see detailed information
   - Check the Prometheus API directly to verify results

3. **Integration with Existing Healthcheck**:
   - Ensure the appropriate Docker image tag is used
   - Check that command-line flags are properly formatted
   - Verify the Prometheus URL is accessible from the container

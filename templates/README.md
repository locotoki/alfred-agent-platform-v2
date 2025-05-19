# Alfred Platform Health Check Templates

This directory contains standardized templates for implementing health checks across all Alfred Platform services.

## Templates Overview

1. `healthcheck.Dockerfile.tmpl` - Standard Dockerfile configuration for health checks
2. `entrypoint.sh.tmpl` - Standard entrypoint script for service initialization with health check integration

## Usage Guide

### Dockerfile Integration

To integrate the health check template into your service's Dockerfile:

1. Copy the relevant sections from `healthcheck.Dockerfile.tmpl` into your service's Dockerfile
2. Replace `${BASE_IMAGE}` with your actual base image
3. Customize the health check environment variables if needed
4. Ensure your service exposes a health endpoint at the specified port and path

Example:

```dockerfile
# First stage: Get the healthcheck binary
FROM gcr.io/distroless/static-debian12:nonroot AS healthcheck
WORKDIR /app
COPY --from=ghcr.io/alfred-health/healthcheck:latest /usr/local/bin/healthcheck /usr/local/bin/healthcheck

# Main application stage
FROM python:3.11-slim AS app

# Install healthcheck binary from first stage
COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck

# Set up health check environment variables
ENV HEALTH_CHECK_PORT=8080
ENV HEALTH_CHECK_PATH=/health
ENV METRICS_EXPORTER_PORT=9091

# Set healthcheck command
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD ["/usr/local/bin/healthcheck", \
         "--export-prom", ":${METRICS_EXPORTER_PORT}", \
         "--interval", "30s", \
         "--port", "${HEALTH_CHECK_PORT}", \
         "--path", "${HEALTH_CHECK_PATH}"]

# Copy your application code
COPY . /app
WORKDIR /app

# Copy the entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["python", "-m", "myservice.app"]
```

### Entrypoint Script Integration

To use the entrypoint script template:

1. Copy `entrypoint.sh.tmpl` to your service directory as `entrypoint.sh`
2. Customize the script to start your specific service
3. Make it executable with `chmod +x entrypoint.sh`
4. Reference it in your Dockerfile as shown above

## Customization Points

The following variables can be customized for each service:

- `HEALTH_CHECK_PORT`: Port where your service's health endpoint is exposed (default: 8080)
- `HEALTH_CHECK_PATH`: Path to your service's health endpoint (default: /health)
- `HEALTH_CHECK_INTERVAL`: How often the health check should run (default: 30s)
- `METRICS_EXPORTER_PORT`: Port where Prometheus metrics will be exposed (default: 9091)

## Implementation Requirements

All services must:

1. Expose a health endpoint that returns appropriate HTTP status codes:
   - 200: Service is healthy
   - 429/503: Service is degraded
   - 500/502: Service is unhealthy

2. Allow metrics to be exported on port 9091 (or custom port if specified)

3. Use the standard healthcheck binary with the appropriate parameters

## Validation

The CI pipeline includes validation to ensure all services implement the standardized health check pattern correctly. Services that don't comply will fail the health check validation step.

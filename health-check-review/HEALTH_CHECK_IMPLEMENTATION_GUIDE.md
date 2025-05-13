# Health Check Implementation Guide

This guide provides detailed instructions for implementing and maintaining standardized health checks across all services in the Alfred Agent Platform v2.

## Quick Reference

| Service Type | Health Check Pattern | Example |
|-------------|----------------------|---------|
| HTTP API | `healthcheck --http http://localhost:<PORT>/health` | `healthcheck --http http://localhost:8080/health` |
| Redis | `healthcheck --redis redis://localhost:<PORT>` | `healthcheck --redis redis://localhost:6379` |
| PostgreSQL | `healthcheck --postgres postgres://<USER>:<PASS>@localhost:<PORT>/<DB>` | `healthcheck --postgres postgres://postgres:postgres@localhost:5432/postgres` |
| Generic TCP | `healthcheck --tcp localhost:<PORT>` | `healthcheck --tcp localhost:9000` |

## Implementing Health Checks for New Services

### 1. Add Health Check Binary to Dockerfile

For all service containers, add the health check binary using a multi-stage build:

```dockerfile
FROM ghcr.io/alfred/healthcheck:0.3.1 AS healthcheck

FROM <your-base-image>

# Other Dockerfile content...

# Copy healthcheck binary
COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck

# Make it executable
RUN chmod +x /usr/local/bin/healthcheck
```

### 2. Implement Health Check Endpoint

For HTTP services, implement a `/health` endpoint that:

1. Returns a 200 OK status code when the service is healthy
2. Includes service name and version in the response
3. Performs basic dependency checks if possible

Example FastAPI implementation:

```python
from fastapi import FastAPI, Response, status

app = FastAPI()

@app.get("/health")
async def health_check():
    # Basic dependency checks
    dependencies_healthy = await check_dependencies()
    
    if not dependencies_healthy:
        return Response(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={"status": "unhealthy", "message": "Dependencies unavailable"}
        )
    
    return {
        "status": "healthy",
        "service": "my-service",
        "version": "1.0.0"
    }

async def check_dependencies():
    # Implement basic connectivity checks to databases, caches, etc.
    return True
```

### 3. Configure Docker Compose Health Check

Add the appropriate health check configuration to your service in the Docker Compose file:

```yaml
services:
  my-service:
    # Other service configuration...
    healthcheck:
      test: ["CMD", "healthcheck", "--http", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 15s
```

### 4. Test Health Check

Validate that your health check works properly:

```bash
# Start the service
docker-compose up -d my-service

# Check health status
docker inspect --format='{{.State.Health.Status}}' alfred-agent-platform-v2_my-service_1

# View health check logs
docker inspect --format='{{range .State.Health.Log}}{{println .Output}}{{end}}' alfred-agent-platform-v2_my-service_1
```

## Service-Specific Health Check Implementation

### HTTP Services

HTTP services should implement a `/health` endpoint with the following features:

1. **Basic Health Response**
   ```json
   {
     "status": "healthy",
     "service": "service-name",
     "version": "1.0.0"
   }
   ```

2. **Extended Health Response (Recommended)**
   ```json
   {
     "status": "healthy",
     "service": "service-name",
     "version": "1.0.0",
     "dependencies": {
       "database": "healthy",
       "cache": "healthy",
       "external-api": "healthy"
     },
     "uptime": 3600,
     "timestamp": "2025-05-13T10:15:30Z"
   }
   ```

### Database Services

For PostgreSQL-specific health checks, ensure the database server is actually accepting connections:

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=30s \
  CMD healthcheck --postgres postgres://postgres:postgres@localhost:5432/postgres
```

### Cache Services

For Redis-specific health checks:

```dockerfile
HEALTHCHECK --interval=15s --timeout=5s --retries=3 --start-period=10s \
  CMD healthcheck --redis redis://localhost:6379
```

### Generic TCP Services

For services that don't expose HTTP endpoints but have a TCP port:

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=15s \
  CMD healthcheck --tcp localhost:9000
```

## Advanced Health Check Configuration

### Health Check Parameters

The health checker binary supports several parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--timeout` | Request timeout in seconds | 5s |
| `--retries` | Number of retry attempts | 1 |
| `--interval` | Time between retries | 1s |
| `--status-codes` | Comma-separated list of valid HTTP status codes | 200 |
| `--headers` | Custom HTTP headers (format: "Key: Value") | none |
| `--body` | Expected response body substring | none |
| `--insecure` | Skip TLS verification | false |

Example with advanced options:

```
healthcheck --http http://localhost:8080/health \
  --timeout 10s \
  --retries 3 \
  --interval 2s \
  --status-codes 200,201,202 \
  --headers "Authorization: Bearer token" \
  --body "healthy"
```

### Health Check for Secured Services

For services requiring authentication:

```yaml
services:
  secure-service:
    # Other service configuration...
    healthcheck:
      test: ["CMD", "healthcheck", "--http", "http://localhost:8000/health", "--headers", "X-API-Key: health-check-key"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 15s
```

## Troubleshooting Health Checks

### Common Issues

1. **Service Marked Unhealthy**
   - Check service logs for errors
   - Verify the health endpoint is accessible
   - Ensure dependencies are available
   - Check for resource constraints (CPU, memory)

2. **Health Check Timeout**
   - Increase the timeout value in Docker Compose
   - Check for slow dependencies
   - Optimize the health check endpoint

3. **Health Check Permission Issues**
   - Ensure the health check binary has execute permissions
   - Verify the user has permissions to access the endpoint

### Debugging Commands

```bash
# Check health status
docker inspect --format='{{.State.Health.Status}}' <container_name>

# View health check logs
docker inspect --format='{{range .State.Health.Log}}{{println .Output}}{{end}}' <container_name>

# Test health check manually
docker exec <container_name> healthcheck --http http://localhost:<PORT>/health

# View health check configuration
docker inspect --format='{{.Config.Healthcheck}}' <container_name>
```

## Integrating with Monitoring

### Prometheus Metric Exposition

To expose health metrics to Prometheus, add the following endpoint to your services:

```python
from prometheus_client import generate_latest, REGISTRY, Gauge

# Create a gauge for service health
health_gauge = Gauge('service_health', 'Service Health Status (1=healthy, 0=unhealthy)', ['service'])

@app.get("/metrics")
async def metrics():
    # Update health gauge
    is_healthy = True  # Determine based on health check
    health_gauge.labels(service="my-service").set(1 if is_healthy else 0)
    
    # Return all prometheus metrics
    return Response(content=generate_latest(REGISTRY), media_type="text/plain")
```

### Alert Configuration

Example Prometheus alert rule for health checks:

```yaml
groups:
- name: health-alerts
  rules:
  - alert: ServiceUnhealthy
    expr: up{job=~".*service"} == 0
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "Service {{ $labels.instance }} is down"
      description: "Service {{ $labels.instance }} has been unhealthy for more than 2 minutes."
```

## Maintenance and Best Practices

1. **Regular Testing**
   - Periodically validate health checks by simulating failures
   - Verify that health status is correctly reflected in monitoring

2. **Documentation**
   - Document health check endpoints for each service
   - Update dependency relationships in service documentation

3. **Standard Patterns**
   - Use consistent health check patterns across similar services
   - Follow the standardized response format for all health endpoints

4. **Dependency Monitoring**
   - Include dependency status in health check responses
   - Implement graceful degradation for non-critical dependencies

5. **Version Control**
   - Keep health check configurations in version control
   - Review health check changes as part of code review process

## Health Check Automation

### CI/CD Integration

Include health check validation in your CI/CD pipeline:

```yaml
# Example GitHub Action
name: Validate Health Checks

on:
  pull_request:
    paths:
      - 'services/*/Dockerfile'
      - 'docker-compose*.yml'

jobs:
  validate-health-checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Validate Health Check Configuration
        run: ./scripts/validate-health-checks.sh
```

### Automated Update Script

Use the provided script to update health checks across all services:

```bash
./scripts/update-healthcheck-binary.sh
```

This script automatically:
1. Updates Dockerfiles to include the health check binary
2. Configures appropriate health check commands based on service type
3. Updates Docker Compose health check configurations
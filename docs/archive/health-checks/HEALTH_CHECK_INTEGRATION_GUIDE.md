# Health Check Integration Guide for New Services

This guide provides detailed instructions for implementing standardized health checks in any new service added to the Alfred Agent Platform v2.

## Overview

All services in the Alfred Agent Platform v2 must implement standardized health checks that provide:

1. **Health Status**: Detailed service health information
2. **Simple Health Probe**: Lightweight health check for container orchestration
3. **Metrics Export**: Standard Prometheus metrics for monitoring

## Health Check Requirements

Every service must implement:

1. **Required Endpoints**:
   - `/health`: Detailed health status with dependency information
   - `/healthz`: Simple health probe for container orchestration
   - `/metrics`: Prometheus-compatible metrics

2. **Docker Configuration**:
   - Define a healthcheck command in docker-compose.yml
   - Expose metrics port 9091
   - Add prometheus.metrics.port label

3. **Response Formats**:
   - `/health`: JSON with status, version, and services objects
   - `/healthz`: Simple JSON with status field
   - `/metrics`: Prometheus text format

## Implementation Methods

Choose one of these implementation methods based on your service type:

### A. Binary-Based Implementation (Recommended)

This approach uses the standard healthcheck binary and is ideal for services where you're primarily configuring the Docker environment.

#### Step 1: Update Dockerfile

```dockerfile
FROM ghcr.io/alfred/healthcheck:0.4.0 AS healthcheck
FROM <your-base-image>

# Other Dockerfile commands...

# Copy healthcheck binary
COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck

# Expose application and metrics ports
EXPOSE <your-app-port>
EXPOSE 9091

# Run the application with metrics export
CMD ["sh", "-c", "/usr/local/bin/healthcheck --export-prom :9091 & <your-application-command>"]
```

#### Step 2: Update docker-compose.yml

```yaml
your-service:
  build:
    context: ./services/your-service
    dockerfile: Dockerfile
  image: your-service:latest
  container_name: your-service
  ports:
    - "<host-port>:<container-port>"
    - "<metrics-host-port>:9091"  # Map metrics port to host
  environment:
    # Your environment variables...
  healthcheck:
    test: ["CMD", "healthcheck", "--http", "http://localhost:<your-app-port>/health"]
    interval: 30s
    timeout: 20s
    retries: 5
    start_period: 45s
  # Other configurations...
  labels:
    # Other labels...
    prometheus.metrics.port: "9091"
```

### B. Direct Implementation

This approach directly implements health endpoints in your application code and is ideal for services where you have full code access.

#### Step 1: Update Application Code

**FastAPI Example**:

```python
import threading
import uvicorn
from fastapi import FastAPI, Response
import prometheus_client

# Create main app
app = FastAPI()

# Create metrics app
metrics_app = FastAPI()

# Health endpoint
@app.get("/health")
async def health():
    """Health check endpoint."""
    # Check dependencies
    db_status = "ok" if check_database() else "error"
    cache_status = "ok" if check_cache() else "error"
    
    # Determine overall status
    services = {
        "database": db_status,
        "cache": cache_status
    }
    status = "error" if "error" in services.values() else "ok"
    
    return {
        "status": status,
        "version": "1.0.0",
        "services": services
    }

# Simple health probe
@app.get("/healthz")
async def healthz():
    """Simple health check for container probes."""
    return {"status": "ok"}

# Metrics endpoint for the metrics app
@metrics_app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint."""
    return Response(
        content=prometheus_client.generate_latest(),
        media_type="text/plain"
    )

# Start metrics server on separate port
@app.on_event("startup")
async def start_metrics_server():
    """Start metrics server on port 9091."""
    thread = threading.Thread(
        target=uvicorn.run,
        args=(metrics_app,),
        kwargs={
            "host": "0.0.0.0",
            "port": 9091,
            "log_level": "error"
        },
        daemon=True
    )
    thread.start()
```

**Express.js Example**:

```javascript
const express = require('express');
const app = express();
const promClient = require('prom-client');

// Create a Registry for metrics
const register = new promClient.Registry();

// Create metrics
const serviceHealth = new promClient.Gauge({
  name: 'service_health',
  help: 'Service health status (1 = up, 0 = down)',
  registers: [register]
});
serviceHealth.set(1);

// Health check endpoint
app.get('/health', (req, res) => {
  // Check dependencies
  const dbStatus = checkDatabase() ? 'ok' : 'error';
  const cacheStatus = checkCache() ? 'ok' : 'error';
  
  const services = {
    database: dbStatus,
    cache: cacheStatus
  };
  
  const hasError = Object.values(services).includes('error');
  
  if (hasError) {
    serviceHealth.set(0);
  } else {
    serviceHealth.set(1);
  }
  
  res.json({
    status: hasError ? 'error' : 'ok',
    version: '1.0.0',
    services: services
  });
});

// Simple health probe
app.get('/healthz', (req, res) => {
  res.json({ status: 'ok' });
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Create separate metrics server on port 9091
const metricsApp = express();
metricsApp.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Start main app
app.listen(3000, () => {
  console.log('App listening on port 3000');
});

// Start metrics server
metricsApp.listen(9091, () => {
  console.log('Metrics server listening on port 9091');
});
```

#### Step 2: Update docker-compose.yml

```yaml
your-service:
  build:
    context: ./services/your-service
    dockerfile: Dockerfile
  image: your-service:latest
  container_name: your-service
  ports:
    - "<host-port>:<container-port>"
    - "<metrics-host-port>:9091"  # Map metrics port to host
  # Other configurations...
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:<your-app-port>/health"]
    interval: 30s
    timeout: 20s
    retries: 5
    start_period: 45s
  labels:
    # Other labels...
    prometheus.metrics.port: "9091"
```

## Port Mapping Convention

To avoid port conflicts, follow this port mapping convention for metrics:

| Service | Host Port |
|---------|-----------|
| agent-core | 9091 |
| alfred-bot | 9095 |
| model-registry | 9093 |
| model-router | 9094 |
| agent-financial | 9096 |
| agent-legal | 9097 |
| ui-chat | 9098 |
| agent-rag | 9099 |
| ui-admin | 9100 |
| *new-service* | 9101+ |

## Testing Your Implementation

After implementing health checks, verify them with:

1. **Manual Testing**:
   ```bash
   # Check health endpoint
   curl -s http://localhost:<host-port>/health | jq
   
   # Check metrics endpoint
   curl -s http://localhost:<metrics-host-port>/metrics | head
   
   # Check Docker healthcheck
   docker inspect --format='{{.State.Health.Status}}' <container-name>
   ```

2. **Automated Testing**:
   ```bash
   ./scripts/healthcheck/verify-health-endpoints.sh
   ```

3. **Update Prometheus Configuration**:
   ```bash
   ./scripts/healthcheck/update-prometheus-config.sh
   ```

## Prometheus Integration

After adding a new service:

1. Update the prometheus.yml configuration:
   ```bash
   ./scripts/healthcheck/update-prometheus-config.sh
   ```

2. Restart Prometheus:
   ```bash
   docker-compose restart monitoring-metrics
   ```

3. Verify metrics in Prometheus UI (http://localhost:9090):
   - Check if your service appears in targets
   - Query: `service_health{service="your-service"}`

## Troubleshooting

### Common Issues

1. **Health Endpoint Returns 404**:
   - Verify endpoint implementation in code
   - Check URL path (should be exactly `/health`)
   - Ensure server is listening on the correct port

2. **Metrics Not Appearing in Prometheus**:
   - Verify metrics server is running on port 9091
   - Check prometheus.yml configuration
   - Ensure port mapping is correct (host-port:9091)

3. **Docker Healthcheck Failing**:
   - Check container logs with `docker logs <container-name>`
   - Verify healthcheck command is correct
   - Ensure service is fully initialized before health checks

### Debugging Tips

1. Check service logs: `docker logs <service-name>`
2. Enter container shell: `docker exec -it <service-name> /bin/bash`
3. Test endpoints inside container: `curl -s http://localhost:<port>/health`
4. Verify metrics port: `netstat -tulpn | grep 9091` (inside container)
5. Check Prometheus targets: Open http://localhost:9090/targets in browser

## Best Practices

1. **Dependency Tracking**:
   - Track all service dependencies in health status
   - Handle dependency failures gracefully

2. **Metrics Naming**:
   - Use consistent metric names across services
   - Follow Prometheus naming conventions

3. **Error Handling**:
   - Provide appropriate status codes (200 for ok/degraded, 503 for error)
   - Include detailed error information in health response

4. **Performance**:
   - Keep health checks lightweight
   - Avoid expensive operations in health checks

5. **Logging**:
   - Log health check failures
   - Include context for troubleshooting

## Reference Materials

- [Health Check Standard](./docs/HEALTH_CHECK_STANDARD.md)
- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Express.js Documentation](https://expressjs.com/)
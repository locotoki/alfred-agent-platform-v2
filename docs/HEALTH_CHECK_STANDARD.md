# Health Check Standard

This document outlines the standardized health check implementation required for all services in the Alfred Agent Platform v2.

## Required Endpoints

Every service MUST implement these three health-related endpoints:

### 1. `/health` - Detailed Health Status

The primary health check endpoint that returns detailed status information.

- **Purpose**: Used by monitoring systems (Prometheus/Grafana) and service dependencies
- **Format**: JSON response with standardized schema
- **Schema**:
  ```json
  {
    "status": "ok|degraded|error",
    "version": "1.0.0",
    "services": {
      "dependency1": "ok|degraded|error",
      "dependency2": "ok|degraded|error"
    }
  }
  ```
- **Status Codes**:
  - 200: Service is healthy (even in degraded state)
  - 503: Service is in error state

### 2. `/healthz` - Simple Health Probe

A lightweight health check for container orchestration.

- **Purpose**: Used by Docker/Kubernetes for fast container health probes
- **Format**: Simple JSON with minimal processing overhead
- **Schema**:
  ```json
  {
    "status": "ok"
  }
  ```
- **Status Codes**:
  - 200: Service is operational
  - 503: Service is not operational

### 3. `/metrics` - Prometheus Metrics

An endpoint for exposing service metrics in Prometheus format.

- **Purpose**: Used by Prometheus for metrics collection
- **Format**: Plain text in Prometheus exposition format (IMPORTANT: no leading whitespace!)
- **Required metrics**: At minimum, services must expose:
  - `<service>_up` (gauge, 1 = up)
  - `<service>_requests_total` (counter)
  - Other service-specific metrics as appropriate

**IMPORTANT**: Prometheus metrics must not have any leading whitespace before metric names. Each line should start at the first column with no indentation. Indented metrics will cause Prometheus scraping to fail with "invalid metric name" errors.

## Implementation Examples

### FastAPI Example

```python
from fastapi import FastAPI, Response
from pydantic import BaseModel
import os

app = FastAPI()

class HealthResponse(BaseModel):
    status: str = "ok"
    version: str = "1.0.0"
    services: dict = {}

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Detailed health check endpoint"""
    # Check dependencies
    db_status = "ok" if check_database_connection() else "error"
    cache_status = "ok" if check_cache_connection() else "error"
    
    # Determine overall status
    services = {
        "database": db_status,
        "cache": cache_status
    }
    overall = "error" if "error" in services.values() else "ok"
    
    return HealthResponse(
        status=overall,
        services=services
    )

@app.get("/healthz")
async def simple_health():
    """Simple health check for container probes"""
    return {"status": "ok"}

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    metrics_text = """# HELP service_up Service availability
# TYPE service_up gauge
service_up 1
# HELP service_requests_total Total requests processed
# TYPE service_requests_total counter
service_requests_total 123"""
    return Response(content=metrics_text, media_type="text/plain")
```

### Node.js Express Example

```javascript
const express = require('express');
const app = express();

// Detailed health check
app.get('/health', (req, res) => {
  const dbStatus = checkDatabaseConnection() ? 'ok' : 'error';
  const cacheStatus = checkCacheConnection() ? 'ok' : 'error';
  
  const services = {
    database: dbStatus,
    cache: cacheStatus
  };
  
  const hasError = Object.values(services).includes('error');
  
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

// Prometheus metrics
app.get('/metrics', (req, res) => {
  const metrics = `# HELP service_up Service availability
# TYPE service_up gauge
service_up 1
# HELP service_requests_total Total requests processed
# TYPE service_requests_total counter
service_requests_total ${requestCounter}`;

  res.set('Content-Type', 'text/plain');
  res.send(metrics);
});
```

## Docker Health Check Configuration

All services must use a consistent health check configuration in docker-compose:

```yaml
healthcheck:
  test: ["CMD", "healthcheck", "--http", "http://localhost:<PORT>/health"]
  interval: 30s
  timeout: 20s
  retries: 5
  start_period: 45s
```

## Validation

The standardized health check implementation is validated using the `validate-monitoring.sh` script, which checks both monitoring services and key application services for compliance with these standards.

## Adding New Services

When adding a new service:

1. Implement all three required endpoints using the standard schemas
2. Configure the Docker health check to use the `/health` endpoint
3. Update `standardize-service-health.sh` to include the new service
4. Update `validate-monitoring.sh` to validate the new service's endpoints

## Troubleshooting

If a service is showing as unhealthy in monitoring:

1. Check that all three endpoints are implemented correctly
2. Verify the Docker health check configuration is correct
3. Ensure all dependencies are properly available
4. Use `standardize-service-health.sh` to fix common issues
# Service Patches

This directory contains patches to improve the Alfred Agent Platform services.

## Health Endpoint Patches

### Atlas Service Health Endpoint

#### Implementation (fixed_metrics.py)

The `fixed_metrics.py` file contains the implemented patch for Atlas health endpoints. It has been directly applied to the Atlas service and:

- Makes `/healthz` always return 200 OK with `{"status":"ok"}` (needed for container health checks)
- Adds a new `/health` endpoint with detailed status information
- Reports status of connections to other services (RAG Gateway, OpenAI, Supabase)

#### How to Apply:

The patch is applied in two ways:

1. For a running container:
   ```bash
   ./apply-health-fix.sh
   ```

2. For new deployments, use the Docker Compose file:
   ```bash
   docker-compose -f docker-compose.combined-fixed.yml -f docker-compose.atlas-fix.yml up -d
   ```

#### Original Template (atlas-health-endpoint.py)

The `atlas-health-endpoint.py` file contains the original template for implementing health endpoints in the Atlas service.

### RAG Gateway Health Endpoint (rag-gateway-health-endpoint.py)

This patch adds a standardized `/health` endpoint to the RAG Gateway service:

- `/health` - Returns detailed health status with service checks
- Standardizes the existing `/healthz` endpoint

#### Implementation Steps:

1. Copy the code from `rag-gateway-health-endpoint.py` into your RAG Gateway service codebase
2. Add the health router to your FastAPI app in the main application file:

```python
from health_endpoints import health_router  # Adjust import path as needed

# Add this to your FastAPI app initialization
app.include_router(health_router)
```

## Usage

These patches provide standardized health endpoints that can be used for:

1. Kubernetes liveness/readiness probes
2. Monitoring systems (Prometheus, Grafana)
3. Service discovery
4. Load balancers

The health endpoints follow standard conventions:

- `/health` - Detailed health status (returns 200 OK if healthy, 503 if degraded)
- `/healthz` - Simple health check (returns 200 OK if service is running)

## Response Format

Both endpoints return JSON responses in the following format:

```json
{
  "status": "ok", // "ok" or "degraded"
  "version": "1.0.0",
  "services": {
    "database": "ok", // "ok", "degraded", "error", or "unknown"
    "rag_gateway": "ok",
    // Other service statuses
  }
}
```
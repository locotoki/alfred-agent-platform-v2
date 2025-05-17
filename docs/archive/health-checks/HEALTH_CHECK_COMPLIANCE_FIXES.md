# Health Check Compliance Fixes

This document outlines the specific changes needed to bring all services into compliance with the health check standard defined in `docs/HEALTH_CHECK_STANDARD.md`.

## Core Infrastructure Services

### 1. Redis Service

**Current Issue:**
- Using `healthcheck --redis redis://localhost:6379` instead of standard `/health` endpoint
- No exposed metrics endpoint

**Recommended Fix:**
1. Create a small HTTP wrapper service for Redis health checks that exposes standard endpoints
2. Update docker-compose.yml:
```yaml
  redis:
    image: redis:7-alpine
    # ... existing configuration ...
    healthcheck:
      test: ["CMD", "healthcheck", "--http", "http://localhost:6379/health"]
      interval: 30s
      timeout: 20s
      retries: 5
      start_period: 45s
    # Add label for metrics port
    labels:
      - "prometheus.metrics.port=9091"
```

### 2. PubSub Emulator

**Current Issue:**
- Using `healthcheck --http http://localhost:8085/v1/projects/alfred-agent-platform/topics` (non-standard path)
- No standardized `/health` endpoint

**Recommended Fix:**
1. Create a small HTTP wrapper service for PubSub health checks
2. Update docker-compose.yml:
```yaml
  pubsub-emulator:
    # ... existing configuration ...
    healthcheck:
      test: ["CMD", "healthcheck", "--http", "http://localhost:8085/health"]
      interval: 30s
      timeout: 20s
      retries: 5
      start_period: 45s
    # Add label for metrics port
    labels:
      - "prometheus.metrics.port=9091"
```

## Agent Services

### 3. Update Agent-Core Health Response

**Current Issue:**
- Returns `{"status":"healthy"}` instead of standard format
- Does not include version and services information

**Recommended Fix:**
Update the `/health` endpoint implementation in `libs/agent_core/health/app_factory.py`:

```python
@health_app.get("/health")
async def health_check() -> dict:
    """Detailed health check endpoint used by monitoring systems and dependencies."""
    service_deps = dependency_tracker.check_dependencies()
    # Map "healthy" to "ok", "unhealthy" to "error" to comply with standard
    mapped_deps = {k: "ok" if v == "healthy" else "error" if v == "unhealthy" else v 
                   for k, v in service_deps.items()}
    overall_status = "error" if "error" in mapped_deps.values() else "ok"

    return {
        "status": overall_status, 
        "version": version, 
        "services": mapped_deps
    }
```

### 4. Update Social-Intel Health Response

**Current Issue:**
- Uses non-standard health response format
- Missing `/healthz` endpoint

**Recommended Fix:**
Update `services/social-intel/app/health_check.py`:

```python
@health_router.get("/health")
async def detailed_health():
    """Detailed health check including component status."""
    global health_state
    
    # Add current time
    health_state["last_check"] = time.time()
    
    # Map to standard format
    status = "ok" if health_state["status"] == "healthy" else \
             "degraded" if health_state["status"] == "degraded" else "error"
    
    # Map component status
    services = {}
    for name, info in health_state["components"].items():
        services[name] = "ok" if info["status"] == "healthy" else "error"
    
    # Return in standard format
    return {
        "status": status,
        "version": "1.0.0",  # Get actual version
        "services": services
    }

@health_router.get("/healthz")
async def simple_health():
    """Simple health check for container probes."""
    global health_state
    if health_state["status"] == "unhealthy":
        return Response(content='{"status":"error"}', 
                       media_type="application/json", 
                       status_code=503)
    return {"status": "ok"}
```

## Web Services

### 5. Standardize UI Services

**Current Issue:**
- UI services (ui-admin, ui-chat) have inconsistent health check implementations
- Some use wget instead of the standard healthcheck binary

**Recommended Fix:**
Update docker-compose.override.ui-chat.yml:
```yaml
services:
  ui-chat:
    # ... existing configuration ...
    healthcheck:
      test: ["CMD", "healthcheck", "--http", "http://localhost:8501/health"]
      interval: 30s
      timeout: 20s
      retries: 5
      start_period: 45s
```

Update mission-control (ui-admin) health check in docker-compose.override.mission-control.yml:
```yaml
services:
  ui-admin:
    # ... existing configuration ...
    healthcheck:
      test: ["CMD", "healthcheck", "--http", "http://localhost:3000/health"]
      interval: 30s
      timeout: 20s
      retries: 5
      start_period: 45s
```

## Monitoring Services

### 6. Standardize Monitoring Services

**Current Issue:**
- Monitoring services use different paths for health checking

**Recommended Fix:**
Implement standard health endpoints for monitoring services and update docker-compose.yml:

```yaml
services:
  monitoring-metrics:
    # ... existing configuration ...
    healthcheck:
      test: ["CMD", "healthcheck", "--http", "http://localhost:9090/health"]
      interval: 30s
      timeout: 20s
      retries: 5
      start_period: 45s
  
  monitoring-db:
    # ... existing configuration ...
    healthcheck:
      test: ["CMD", "healthcheck", "--http", "http://localhost:9187/health"]
      interval: 30s
      timeout: 20s
      retries: 5
      start_period: 45s
```

## Implementation Plan

1. **High Priority Services**:
   - Start with core infrastructure (Redis, PubSub)
   - Then fix agent services (agent-core, social-intel)

2. **Medium Priority Services**:
   - Update UI services (ui-admin, ui-chat)
   - Fix monitoring services

3. **Validation Process**:
   - After each service update, run `scripts/healthcheck/run-full-healthcheck.sh` to validate
   - Verify with `docker-compose ps` to confirm health status improvement

4. **Rolling Update Strategy**:
   - Update services one at a time to minimize disruption
   - Restart services after changes using `docker-compose restart <service-name>`
   - Verify dependencies work properly after each update

## Troubleshooting Guidance

If services remain unhealthy after updates:

1. Check logs: `docker logs <service-name>`
2. Verify endpoints manually:
   - `curl http://localhost:<port>/health`
   - `curl http://localhost:<port>/healthz`
   - `curl http://localhost:<port>/metrics`
3. Ensure the service can access its dependencies
4. Verify environment variables are correctly set
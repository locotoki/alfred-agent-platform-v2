# Docker Compose Health Checks Guide

This document details the health check implementation for containerized services in the Alfred Agent Platform v2.

## Health Check Architecture

The platform implements a comprehensive health check system consisting of:

1. **Service Health Endpoints**
   - `/health` - Detailed health status with dependency checks
   - `/healthz` - Simple health probe for container orchestration
   - `/metrics` - Prometheus metrics endpoint

2. **Container Health Checks**
   - Configured in `docker-compose.yml`
   - Used by Docker to determine container health status
   - Integrated with service dependencies

3. **Metrics Collection**
   - Dedicated exporters for specialized services
   - Standard port assignments (909x range)
   - Prometheus scrape configuration

4. **Monitoring Integration**
   - Grafana dashboards
   - Alerting rules
   - Service health panels

## Docker Compose Configuration

Health checks are configured in the Docker Compose files:

```yaml
services:
  example-service:
    image: example-service:latest
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    ports:
      - "8080:8080"  # Application port
      - "9091:9091"  # Metrics port
```

## Standard Health Check Implementation

Each service implements health checks following these patterns:

### FastAPI/Python Services

```python
@app.get("/health")
async def health():
    return {
        "status": "ok",
        "timestamp": datetime.utcnow().isoformat(),
        "version": settings.VERSION,
        "dependencies": await check_dependencies()
    }

@app.get("/healthz")
async def healthz():
    return {"status": "ok"}
```

### Node.js Services

```javascript
app.get('/health', async (req, res) => {
  const dependencies = await checkDependencies();
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: process.env.VERSION,
    dependencies
  });
});

app.get('/healthz', (req, res) => {
  res.json({ status: 'ok' });
});
```

## Health Check Verification

To verify health checks are working correctly:

```bash
# Test detailed health endpoint
curl http://localhost:8080/health | jq

# Test simple health probe
curl http://localhost:8080/healthz

# Check container health status
docker ps --format "{{.Names}}: {{.Status}}"

# Check metrics endpoint
curl http://localhost:9091/metrics
```

## Common Health Check Issues

1. **Missing Dependencies**
   - Service dependencies not available
   - Connection timeouts or errors

2. **Configuration Problems**
   - Incorrect port mappings
   - Missing environment variables

3. **Resource Constraints**
   - Memory limits exceeded
   - CPU throttling

## Monitoring

Health checks are monitored through:

- Prometheus: http://localhost:9090
- Grafana: http://localhost:3005
  - Platform Health Dashboard
  - Service-specific dashboards

## Additional Resources

- [Health Check Standards](../../HEALTH_CHECK_STANDARD.md)
- [Container Monitoring Best Practices](../../docs/monitoring/dashboards.md)

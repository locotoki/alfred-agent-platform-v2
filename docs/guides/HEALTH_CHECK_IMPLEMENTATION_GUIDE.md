# Health Check Implementation Guide

This document provides comprehensive guidance for implementing standardized health checks across all services in the Alfred Agent Platform v2.

## Table of Contents

1. [Standard Pattern](#standard-pattern)
2. [Implementation Process](#implementation-process)
3. [Obtaining the Healthcheck Image](#obtaining-the-healthcheck-image)
4. [CI Integration](#ci-integration)
5. [Troubleshooting](#troubleshooting)
6. [Appendix: Full Example](#appendix-full-example)

## Standard Pattern

### Dockerfile Pattern

Every service must follow this exact pattern in its Dockerfile:

```dockerfile
# ⬇⬇ Must be present in every service Dockerfile ⬇⬇
FROM alfred/healthcheck:0.4.0 AS healthcheck
FROM python:3.11-slim  # or your preferred base image
COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/

# ... Your service-specific content ...

# Expose both application and metrics ports
EXPOSE <service-port>
EXPOSE 9091

# Use healthcheck to wrap your application
CMD ["healthcheck", "--export-prom", ":9091", "--", "<your-command>"]
```

### Docker Compose Configuration

In `docker-compose.yml`, services should include:

```yaml
services:
  your-service:
    # ... other configuration ...
    healthcheck:
      test: ["CMD", "healthcheck", "--http", "http://localhost:<PORT>/health"]
      interval: 30s
      timeout: 20s
      retries: 5
      start_period: 45s
    ports:
      - "<host-port>:<service-port>"
      - "<metrics-port>:9091"  # Map metrics port to unique host port
    labels:
      - metrics_port=9091  # For Prometheus service discovery
```

### Required Health Endpoints

Every service must implement these three health-related endpoints:

1. `/health` - Detailed health status (JSON with dependency status)
2. `/healthz` - Simple health probe for container orchestration
3. `/metrics` - Prometheus metrics endpoint (port 9091)

For implementation details, see language-specific examples in the [Appendix](#appendix-health-endpoint-examples).

### Metrics Port Allocation

The platform uses a consistent port allocation scheme for metrics:

| Service Category | Port Range |
|------------------|------------|
| Core Services | 9091-9099 |
| Infrastructure Services | 9101-9103 |
| Database Services | 9120-9124 |
| Monitoring Services | 9100, 9187 |

## Implementation Process

Follow this phased approach to implement health checks:

### Phase 1: Setup

1. Build the healthcheck image locally:
   ```bash
   cd /home/locotoki/projects/alfred-agent-platform-v2/healthcheck
   docker build -t alfred/healthcheck:0.4.0 .
   ```

2. Push to registry:
   ```bash
   docker tag alfred/healthcheck:0.4.0 ghcr.io/locotoki/alfred/healthcheck:0.4.0
   docker push ghcr.io/locotoki/alfred/healthcheck:0.4.0
   ```

### Phase 2: Fix Dockerfiles

1. Use the fix script to update Dockerfiles:
   ```bash
   cd /home/locotoki/projects/alfred-agent-platform-v2
   ./fix-dockerfile-healthcheck.sh services/model-registry/Dockerfile
   ```

2. Or manually apply the pattern if needed.

### Phase 3: Implement Health Endpoints

Ensure each service implements the required endpoints (`/health`, `/healthz`, `/metrics`).

### Phase 4: Verify Implementation

1. Rebuild the service:
   ```bash
   docker-compose build --no-cache <service>
   ```

2. Start the service:
   ```bash
   docker-compose up -d <service>
   ```

3. Check health status:
   ```bash
   docker ps --format "{{.Names}}:{{.Status}}" | grep <service>
   ```

4. Test health endpoints:
   ```bash
   curl http://localhost:<service-port>/health
   curl http://localhost:<service-port>/healthz
   curl http://localhost:<metrics-port>/metrics
   ```

### Phase 5: Update Documentation

Update the service's README with health check information.

## Obtaining the Healthcheck Image

| Environment | How |
|-------------|-----|
| **Local development** | Build locally:<br>`cd healthcheck && docker build -t alfred/healthcheck:0.4.0 .` |
| **CI / VPN runners** | Pull from registry:<br>`docker pull ghcr.io/locotoki/alfred/healthcheck:0.4.0` |
| **Air-gapped systems** | Load from archive:<br>`docker load -i tools/healthcheck-0.4.0.tar.gz` |

## CI Integration

Add these steps to your CI workflow:

```yaml
- name: Auth to GHCR
  run: echo "${{ secrets.GHCR_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin

- name: Ensure healthcheck image present
  run: |
    if ! docker pull ghcr.io/locotoki/alfred/healthcheck:0.4.0; then
      echo "Registry pull failed, falling back to archive..."
      docker load -i tools/healthcheck-0.4.0.tar.gz || {
        echo "⚠️ Failed to load healthcheck image from archive"
        exit 1
      }
    fi
```

## Troubleshooting

### Common Issues

1. **Container remains unhealthy**:
   ```bash
   docker logs <container-name>
   docker exec <container> healthcheck --http http://localhost:<port>/health
   ```

2. **Healthcheck binary not found**:
   ```bash
   docker exec <container> ls -la /usr/local/bin/healthcheck
   ```

3. **Metrics port not exposed**:
   ```bash
   docker exec <container> netstat -tuln | grep 9091
   ```

4. **Circular dependency in Dockerfile**:
   - Ensure the COPY statement comes after the second FROM statement
   - Use the fix script: `./fix-dockerfile-healthcheck.sh <dockerfile>`

### Verifying Health Check Implementation

Use this script to verify all health checks:

```bash
cd /home/locotoki/projects/alfred-agent-platform-v2
for container in $(docker ps --format "{{.Names}}"); do
  echo "Checking $container..."
  status=$(docker ps --format "{{.Status}}" --filter "name=$container")
  if [[ $status == *"healthy"* ]]; then
    echo "✅ $container is healthy"
  else
    echo "❌ $container is NOT healthy"
  fi
done
```

## Appendix: Full Example

### Example Dockerfile

```dockerfile
FROM alfred/healthcheck:0.4.0 AS healthcheck
FROM python:3.11-slim

WORKDIR /app

# Copy healthcheck binary from the first stage
COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY ./app /app/app

# Set environment variables
ENV PYTHONPATH=/app
ENV PORT=8080

# Expose ports
EXPOSE 8080
EXPOSE 9091

# Use healthcheck to wrap application
CMD ["healthcheck", "--export-prom", ":9091", "--", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
```

### Example Docker Compose Entry

```yaml
services:
  model-router:
    build:
      context: ./services/model-router
      dockerfile: Dockerfile
    image: model-router:latest
    container_name: model-router
    ports:
      - "8080:8080"
      - "9094:9091"  # Map metrics port
    environment:
      - DEBUG=true
      - MODEL_REGISTRY_URL=http://model-registry:8079
      - PORT=8080
    healthcheck:
      test: ["CMD", "healthcheck", "--http", "http://localhost:8080/health"]
      interval: 30s
      timeout: 20s
      retries: 5
      start_period: 45s
    labels:
      - metrics_port=9091
```

### Health Endpoint Examples

#### Python (FastAPI)

```python
from fastapi import FastAPI, Response

app = FastAPI()

@app.get("/health")
async def health():
    return {
        "status": "ok",
        "version": "1.0.0",
        "services": {
            "database": "ok",
            "cache": "ok"
        }
    }

@app.get("/healthz")
async def healthz():
    return {"status": "ok"}

@app.get("/metrics")
async def metrics():
    metrics_text = """# HELP service_up Service availability
# TYPE service_up gauge
service_up 1
# HELP service_requests_total Total requests processed
# TYPE service_requests_total counter
service_requests_total 0"""
    return Response(content=metrics_text, media_type="text/plain")
```

#### Node.js

```javascript
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    version: '1.0.0',
    services: {
      database: 'ok'
    }
  });
});

app.get('/healthz', (req, res) => {
  res.json({ status: 'ok' });
});

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

### Healthcheck Binary Usage

The healthcheck binary supports these flags:

- `--export-prom :PORT` - Export metrics on specified port
- `--http URL` - Check HTTP endpoint health
- `--tcp HOST:PORT` - Check TCP connection
- `--redis redis://HOST:PORT` - Check Redis connection
- `--postgres postgres://USER:PASS@HOST:PORT/DB` - Check PostgreSQL connection

Example usage:
```
healthcheck --export-prom :9091 -- your-command arg1 arg2
```

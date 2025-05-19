# Health Monitoring Guide

This document outlines the health monitoring system for the Alfred Agent Platform v2.

## Health Endpoint Standards

All services in the platform implement standardized health endpoints:

### Basic Health Check

- **Endpoint**: `/healthz`
- **Purpose**: Simple liveness check
- **Response**: `{"status":"ok"}` with HTTP 200
- **Usage**: Container health checks, load balancers

### Detailed Health Check

- **Endpoint**: `/health`
- **Purpose**: Detailed service health with dependencies
- **Response Format**:
  ```json
  {
    "status": "ok|degraded",
    "version": "1.0.0",
    "services": {
      "rag": "ok|degraded|unknown",
      "openai": "ok|degraded|unknown",
      "supabase": "ok|degraded|unknown"
    }
  }
  ```
- **Usage**: Monitoring, dependency tracking

## Service-Specific Health Implementations

### Atlas Service

The Atlas service provides two health endpoints:

1. **Basic Health**: `/healthz`
   - Always returns 200 OK with `{"status":"ok"}`
   - Used for container health checks

2. **Detailed Health**: `/health`
   - Checks RAG Gateway connection
   - Checks OpenAI API connection
   - Checks Supabase connection
   - Returns status of each dependency

Implementation:
- Located in `metrics.py`
- Uses Prometheus metrics for tracking
- Patched with `fixed_metrics.py` to fix container health check issue

### RAG Gateway

The RAG Gateway implements:

1. **Basic Health**: `/healthz`
   - Returns 200 OK with `{"status":"ok"}`
   - Verifies the service is responding

2. **Search Health**: `/healthz?collection=general`
   - Optional parameter to check specific collections
   - Verifies Qdrant connectivity

## Monitoring Setup

The platform includes a comprehensive monitoring stack:

### Prometheus

- **Purpose**: Metrics collection and alerting
- **Endpoint**: http://localhost:9090
- **Configuration**: `/monitoring/prometheus/prometheus.yml`

Collects metrics from:
- Node Exporter (system metrics)
- Postgres Exporter (database metrics)
- Application metrics (Atlas, RAG Gateway)

### Grafana

- **Purpose**: Metrics visualization and dashboards
- **URL**: http://localhost:3005 (login: admin/admin)
- **Configuration**: `/monitoring/grafana/`

Includes dashboards for:
- System overview
- Service health
- Database performance
- API usage

## Health Verification

The platform includes a health verification script:

```bash
./verify-platform.sh
```

This script:
1. Checks all container statuses
2. Verifies health endpoints
3. Tests service-to-service communication
4. Validates data persistence

## Metrics

The platform collects several important metrics:

### System Metrics

- CPU usage
- Memory usage
- Disk I/O
- Network traffic

### Application Metrics

- Request rate
- Response time
- Error rate
- Token usage

### Database Metrics

- Query performance
- Connection count
- Transaction rate
- Disk usage

## Docker Health Checks

The platform uses Docker health checks to monitor container health:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8000/healthz"]
  interval: 30s
  timeout: 5s
  retries: 3
  start_period: 10s
```

These health checks:
- Verify service availability
- Restart containers automatically if they fail
- Provide visual health status in Docker tools

## Alerting (Future)

Future versions will include alerting integration:

- Prometheus Alertmanager
- Slack notifications
- Email alerts
- PagerDuty integration

## Troubleshooting Health Issues

### Common Health Check Failures

1. **Atlas Health Check Failure**
   - **Issue**: Container shows as unhealthy
   - **Solution**: Run `./apply-health-fix.sh`

2. **RAG Gateway Connectivity**
   - **Issue**: Atlas shows RAG as "degraded"
   - **Check**: `curl http://localhost:8501/healthz`
   - **Solution**: Restart RAG Gateway or check logs

3. **Supabase Connection Issues**
   - **Issue**: 401 Authentication errors
   - **Solution**: Run `./disable-auth.sh` for development

4. **Prometheus Scrape Failures**
   - **Issue**: Missing metrics
   - **Check**: `curl http://localhost:9090/-/ready`
   - **Solution**: Check target configuration

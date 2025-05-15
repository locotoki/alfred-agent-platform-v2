# Redis Health Monitoring Implementation

This document provides details about the Redis health check implementation as part of Phase 5 of the Alfred Agent Platform's health check standardization project.

## Overview

Redis is a critical component of the Alfred Agent Platform, serving as a cache, message broker, and data store for various services. Monitoring Redis's health is essential for ensuring overall platform reliability.

This implementation includes:

1. Standardized health check endpoints for Redis
2. Comprehensive metrics collection
3. Prometheus integration
4. Alerting rules for Redis-specific issues

## Implementation Details

### Redis Service Health Check

The Redis service has been updated to use the standard healthcheck binary (v0.4.0) and provides these standard endpoints:

- `/health` - Detailed health status in JSON format
- `/healthz` - Simple health check for container probes
- `/metrics` - Prometheus metrics

The Redis health check wrapper (`health_wrapper.py`) runs alongside Redis and monitors:

- Redis server availability
- Connection status
- Memory usage
- Command processing
- Key metrics
- Persistence status
- Replication status

### Components

The implementation consists of the following components:

#### Dockerfile

A new Dockerfile has been created for Redis that incorporates the standard healthcheck binary:

```dockerfile
FROM alfred/healthcheck:0.4.0 AS healthcheck
FROM redis:7-alpine

COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck
COPY ./health_wrapper.py /app/health_wrapper.py
COPY ./entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh
RUN apk add --no-cache python3 py3-pip
RUN pip3 install --no-cache-dir redis==5.0.1 fastapi==0.104.1 uvicorn==0.23.2 prometheus-client==0.17.1

HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=3 \
  CMD healthcheck --url http://localhost:8080/healthz || exit 1

EXPOSE 6379 8080

CMD ["/entrypoint.sh"]
```

#### Health Wrapper Script

The enhanced `health_wrapper.py` script is a FastAPI application that:

- Monitors Redis connectivity
- Exposes standard health endpoints
- Collects and exports Redis metrics
- Provides detailed health status information

#### Entrypoint Script

A new entrypoint script that launches both Redis and the health monitoring service:

```bash
#!/bin/sh
set -e

# Start Redis server in the background
redis-server --daemonize yes

# Start health monitoring API
python3 /app/health_wrapper.py
```

### Monitoring-Redis Exporter

In addition to the Redis internal health checks, a dedicated Redis metrics exporter (`monitoring-redis`) provides detailed Redis metrics:

- Key statistics (total keys, expires, etc.)
- Memory usage and fragmentation
- Command statistics
- Client connections
- Latency measurements
- Replication metrics

### Metrics

The Redis health implementation exports these metrics:

1. **Standard Health Metrics**:
   - `service_health` - Overall service health status (1.0=up, 0.5=degraded, 0.0=down)

2. **Redis-Specific Metrics**:
   - `redis_up` - Redis server availability
   - `redis_latency_seconds` - Operation latency (ping, info, etc.)
   - `redis_commands_processed_total` - Total commands processed
   - `redis_commands_per_second` - Commands per second
   - `redis_connections_current` - Client connections
   - `redis_connections_rejected_total` - Rejected connections
   - `redis_memory_used_bytes` - Redis memory usage
   - `redis_memory_peak_bytes` - Peak memory usage
   - `redis_memory_fragmentation_ratio` - Memory fragmentation ratio
   - `redis_keys_total` - Total keys by database
   - `redis_keys_evicted_total` - Evicted keys count
   - `redis_keys_expired_total` - Expired keys count
   - `redis_persistence_status` - RDB/AOF persistence status

### Alert Rules

Redis-specific alert rules have been added in `monitoring/prometheus/alerts/redis_health.yml`:

```yaml
groups:
- name: redis_health
  rules:
  - alert: RedisDown
    expr: redis_up == 0
    for: 30s
    labels:
      severity: critical
    annotations:
      summary: "Redis service is down"
      description: "Redis service has been down for more than 30 seconds."

  - alert: RedisHighLatency
    expr: histogram_quantile(0.95, sum(rate(redis_command_latency_seconds_bucket[5m])) by (le)) > 0.1
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "Redis high command latency"
      description: "Redis commands are taking more than 100ms (p95) to execute."

  - alert: RedisHighMemoryUsage
    expr: redis_memory_used_bytes / 1024 / 1024 > 900
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Redis high memory usage"
      description: "Redis is using more than 900MB of memory."

  - alert: RedisConnectionSaturation
    expr: redis_connections > 900
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "Redis connection saturation"
      description: "Redis has more than 900 client connections."
```

## Configuration

### Docker Setup

Redis service is configured with:

```dockerfile
FROM alfred/healthcheck:0.4.0 AS healthcheck
FROM redis:7-alpine
COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck
# ... (other setup)
HEALTHCHECK --interval=30s --timeout=20s --retries=5 --start-period=45s \
  CMD healthcheck --http http://localhost:9091/health || exit 1
```

### Environment Variables

The Redis health check can be configured with these environment variables:

- `REDIS_URL` - Redis connection URL (default: `redis://localhost:6379`)
- `REDIS_DB` - Redis database number (default: `0`)
- `REDIS_HOST` - Redis server hostname (default: `localhost`)
- `REDIS_PORT` - Redis server port (default: `6379`)
- `REDIS_PASSWORD` - Redis server password (optional)

## Integration

Redis health checks are integrated with:

1. **Prometheus** - Redis is included in the `service_health` job
2. **Docker** - Standard healthcheck configuration
3. **Alerting** - Redis-specific alert rules
4. **Grafana** - Redis dashboard integration

## Testing

To verify the Redis health implementation:

1. **Health Check Test**:
   ```bash
   curl http://redis:9091/health
   ```
   Expected result: `{"status":"ok","version":"7.0.0","hostname":"redis","services":{"redis":"ok"}}`

2. **Metrics Test**:
   ```bash
   curl http://redis:9091/metrics
   ```
   Expected result: Prometheus metrics including `service_health` and Redis-specific metrics

3. **Container Health Test**:
   ```bash
   docker inspect --format='{{.State.Health.Status}}' redis
   ```
   Expected result: `healthy`

4. **Load Test**:
   ```bash
   redis-benchmark -h redis -p 6379 -c 100 -n 100000
   ```
   Verify metrics show increased command processing and connections

## Troubleshooting

Common issues and solutions:

1. **Redis not responding**:
   - Check Redis logs: `docker logs redis`
   - Verify Redis process is running: `docker exec redis ps aux | grep redis-server`

2. **Health check not available**:
   - Verify the health wrapper is running: `docker exec redis ps aux | grep health_wrapper`
   - Check health wrapper logs: `docker logs redis | grep "health check wrapper"`

3. **Metrics not showing in Prometheus**:
   - Verify Prometheus configuration includes Redis targets
   - Check if Redis metrics endpoint is accessible: `curl http://redis:9091/metrics`

## Benefits

This implementation provides several benefits:

1. **Standardized Health Reporting**: Follows the same pattern as other services
2. **Comprehensive Metrics**: Detailed Redis-specific metrics
3. **Proactive Monitoring**: Early warning through alert rules
4. **Improved Reliability**: Better visibility into Redis operation
5. **Easy Integration**: Compatible with existing monitoring dashboards

## Future Enhancements

Potential future improvements include:

1. More detailed Redis metrics collection
2. Redis Cluster-specific monitoring
3. Advanced anomaly detection
4. Integration with the central health dashboard
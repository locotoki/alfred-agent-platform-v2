# Niche-Scout Monitoring System

This document describes the monitoring setup for the Niche-Scout proxy service, including:
- Prometheus metrics
- Grafana dashboards
- Alertmanager configurations
- Rollout/rollback procedures

## Monitoring Stack

The monitoring stack consists of:

- **Prometheus**: Collects and stores metrics from the proxy service
- **Alertmanager**: Manages and routes alerts based on rules
- **Grafana**: Provides visualization dashboards for metrics

## Starting the Monitoring Stack

```bash
# Start the entire stack including the proxy service
docker-compose up -d

# Start only the monitoring components
docker-compose up -d prometheus alertmanager grafana
```

## Accessing the Dashboards

- **Prometheus**: http://localhost:9090
- **Alertmanager**: http://localhost:9093
- **Grafana**: http://localhost:3000 (default credentials: admin/admin)

## Grafana Dashboards

Two primary dashboards are provided:

1. **Niche-Scout Overview**: General service metrics and performance
   - URL: http://localhost:3000/d/niche-scout-overview
   - Features:
     - Key performance metrics (error rate, p95 latency, cache hit ratio)
     - Performance trends over time
     - System health information
     - API statistics

2. **Niche-Scout Alerts**: Alert status and thresholds
   - URL: http://localhost:3000/d/niche-scout-alerts
   - Features:
     - Current alert status
     - Alert thresholds visualization
     - Alert history

## Alert Rules

The following alerts are configured:

| Alert Name | Trigger Condition | Duration | Severity |
|------------|-------------------|----------|----------|
| HighErrorRate | Error rate > 5% | 1m | Critical |
| HighLatency | P95 latency > 0.8s | 2m | Warning |
| LowCacheHitRatio | Cache hit ratio < 20% | 5m | Warning |
| RedisConnectionFailed | Redis connection errors > 0 | 1m | Critical |
| ProxyServiceDown | Service not responding | 30s | Critical |

## SLO Targets

The service has the following SLO targets:

- **Availability**: 99.9% uptime
- **Latency**: p95 < 400ms (warning at 800ms)
- **Error Rate**: < 3% (critical at 5%)
- **Cache Hit Ratio**: > 20%

## Metrics Collection

Key metrics collected include:

- `proxy_error_rate`: Rate of errors in requests
- `proxy_p95_latency`: 95th percentile latency in seconds
- `proxy_transform_duration_ms`: Histogram of transformation durations
- `proxy_cache_hit_ratio`: Ratio of cache hits to total requests
- `proxy_api_response_time_ms`: Response time of Social Intelligence API
- `proxy_total_requests`: Counter of total requests processed

## Testing Alerts

A test script is provided to simulate alert conditions:

```bash
# Show help information
./scripts/test-alerts.sh --help

# Simulate high error rate
./scripts/test-alerts.sh --fire error

# Simulate high latency
./scripts/test-alerts.sh --fire latency

# Simulate low cache hit ratio
./scripts/test-alerts.sh --fire cache

# Resolve all alerts
./scripts/test-alerts.sh --resolve
```

## Alertmanager Configuration

Alert notifications are configured to be sent via email. To receive alerts, set the following environment variables:

```bash
# In your .env file or environment
SMTP_USERNAME=your-email@example.com
SMTP_PASSWORD=your-email-password
ALERT_EMAIL=recipient@example.com
```

## Rollout/Rollback Procedures

A script is provided to manage the progressive rollout and emergency rollback:

```bash
# Show help information
./scripts/rollout-toggle.sh --help

# Check current rollout status
./scripts/rollout-toggle.sh --status

# Start 10% canary deployment
./scripts/rollout-toggle.sh --canary

# Set specific percentage
./scripts/rollout-toggle.sh --set 50

# Emergency rollback (sets to 0%)
./scripts/rollout-toggle.sh --rollback
```

### Canary Deployment Process

1. Start with a 10% canary: `./scripts/rollout-toggle.sh --canary`
2. Monitor metrics for 15-30 minutes
3. If stable, increase to 25%: `./scripts/rollout-toggle.sh --set 25`
4. Monitor for another 15-30 minutes
5. If stable, increase to 50%: `./scripts/rollout-toggle.sh --set 50`
6. Monitor for 30 minutes
7. If stable, increase to 100%: `./scripts/rollout-toggle.sh --enable`

### Emergency Rollback Process

If any issues are detected:

1. Immediately execute: `./scripts/rollout-toggle.sh --rollback`
2. Check logs for errors: `docker logs niche-proxy`
3. Verify metrics in Grafana
4. Fix issues before attempting rollout again

## Histogram Bucket Tuning

The metric histograms have been tuned to provide better visibility around our SLO targets:

- Transform Duration: Buckets around 400ms (1, 5, 10, 25, 50, 100, 200, 300, 400, 500, 750, 1000)
- API Response Time: Buckets around 400ms (10, 50, 100, 200, 300, 400, 500, 750, 1000, 1500, 2000, 3000, 5000, 10000)

This provides better resolution around our SLO target of 400ms.
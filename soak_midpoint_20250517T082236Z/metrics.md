# Soak Test Metrics Report
Generated at: 2025-05-17T08:22:42Z
Namespace: metrics
Time period: last 12h

## Error Rate Metrics
### HTTP 5xx Errors
v0.8.1-rc2: 0.01% (3 errors in 30,000 requests)
v0.8.0 baseline: 5.2% (1,560 errors in 30,000 requests)

### Service Availability
- db-api-metrics: 99.99% uptime
- db-admin-metrics: 99.98% uptime
- all /health endpoints: 0 HTTP 500 responses

## Latency Metrics
### Response Times (P50/P90/P99)
- /health endpoint: 12ms / 25ms / 45ms
- /metrics endpoint: 8ms / 15ms / 22ms
- /healthz endpoint: 3ms / 5ms / 8ms

## Resource Usage
### CPU Usage
- db-metrics services: avg 0.02 CPU cores
- Peak during load test: 0.08 CPU cores

### Memory Usage
- db-metrics services: avg 45MB
- Peak during load test: 68MB

## Restart Counts
- db-api-metrics: 0 restarts
- db-admin-metrics: 0 restarts

## Key Improvements from Fix
1. Error handling now properly catches dependency failures
2. /health endpoint returns 503 (not 500) when dependencies are down
3. DEBUG_MODE allows detailed troubleshooting when needed
4. No performance degradation observed

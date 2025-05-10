# Latency Histogram Bucket Tuning & Alert Update

## Summary
This patch optimizes the Prometheus histogram buckets for latency metrics and updates alert rules for better monitoring. The changes include:

1. Tuning `SI_LATENCY_SECONDS` histogram buckets to focus on relevant latency ranges
2. Creating Prometheus alert rules with a focus on 400ms P95 SLO
3. Adding unit tests for the new bucket configuration
4. Adding test scripts and documentation

## Changes Made

### 1. Metrics Tuning
Changed `app/metrics.py` to use optimized buckets:
```python
# Before
buckets=[0.01, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.75, 1.0, 2.0, 5.0, 10.0]

# After 
buckets=[0.05, 0.1, 0.2, 0.4, 0.8, 2]
```

### 2. Alert Rules
Created `prometheus/prom_alert_rules.yml` with:
```yaml
# High latency alert
- alert: HighLatencyP95
  expr: histogram_quantile(0.95, sum(rate(si_latency_seconds_bucket[5m])) by (le)) > 0.4
  for: 2m
  labels:
    severity: warning
  annotations:
    summary: "High API latency detected"
    description: "P95 latency for Social Intelligence API is above 400ms threshold"
```

### 3. Unit Tests
Added unit test in `tests/unit/test_metrics.py` to ensure:
- There are exactly 6 buckets (excluding +Inf)
- The buckets match the specified values

### 4. Documentation & Testing
- Updated README with alert rules and bucket information
- Added test script `tests/check_metrics.sh` to verify metrics endpoint
- Created Prometheus configuration in `prometheus/prometheus.yml`
- Updated Docker Compose to mount alert rules

## Benefits
- **More Relevant Buckets**: Focuses on the most important latency ranges around our 400ms SLO
- **Reduced Cardinality**: Fewer buckets means less storage and query overhead
- **Better Alignment**: Buckets align with warning and critical thresholds
- **Improved Testing**: Added verification for metric configuration

## Verification
After deploying these changes:
1. Run `npm run test:metrics` to verify the 0.4s bucket exists
2. Check Prometheus rules API: `curl localhost:9090/api/v1/rules`
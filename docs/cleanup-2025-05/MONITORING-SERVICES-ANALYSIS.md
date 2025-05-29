# Monitoring Services Analysis - Duplicate Exporters! 📊

## Current Monitoring Stack

### Core Monitoring Services (4)
1. **monitoring-metrics** (Prometheus) - Metrics collection server
2. **monitoring-dashboard** (Grafana) - Visualization dashboard
3. **monitoring-node** - System metrics (CPU, memory, disk)
4. **monitoring-redis** - Redis metrics exporter

### Additional Exporters Found (4)
5. **redis-exporter** - Another Redis exporter! (duplicate)
6. **db-exporter** - PostgreSQL metrics
7. **db-metrics** - Generic database metrics (what is this?)
8. **pubsub-metrics** - PubSub emulator metrics

## Problems Identified

### 1. Duplicate Redis Exporters
- **monitoring-redis** (port 9125)
- **redis-exporter** (port 9101)
- Both are `oliver006/redis_exporter:v1.55.0`
- Exact same image, different ports!

### 2. Confusing Database Metrics
- **db-exporter** - Standard PostgreSQL exporter
- **db-metrics** - Unknown service with SHA256 image
- Previously removed 5 db-*-metrics services

### 3. Missing Health Checks
- monitoring-node shows "unhealthy"
- monitoring-redis shows "unhealthy"
- No health status for Prometheus/Grafana

## Standard Monitoring Stack Should Be:

### Essential (Keep)
1. **Prometheus** (monitoring-metrics) - Collects metrics
2. **Grafana** (monitoring-dashboard) - Visualizes metrics
3. **Node Exporter** (monitoring-node) - System metrics
4. **PostgreSQL Exporter** (db-exporter) - Database metrics
5. **Redis Exporter** (ONE of them) - Cache metrics

### Optional (Evaluate)
6. **PubSub Metrics** - If using PubSub actively

### Remove
- Duplicate redis-exporter OR monitoring-redis
- Unknown db-metrics service

## Recommendations

1. **Remove Duplicates**
   - Keep `redis-exporter` (port 9101)
   - Remove `monitoring-redis` (port 9125)

2. **Investigate Unknown**
   - What is `db-metrics` with SHA256 image?
   - Likely can be removed

3. **Fix Health Checks**
   - monitoring-node and monitoring-redis showing unhealthy
   - May just be misconfigured health endpoints

## Expected Result
From 8 monitoring containers to 5-6 containers
# Metrics Dashboard Implementation

This document outlines the implementation plan for integrating the Phase 5 health metrics into Grafana dashboards for monitoring.

## Overview

The Phase 5 health check standardization has introduced several new metrics:

1. **Service Health Status**: Three-state health reporting (OK, DEGRADED, ERROR)
2. **Database Metrics**: 
   - PostgreSQL connection and query latency metrics
   - MySQL replication lag and connection pool metrics
   - SQLite checksum and query execution metrics
3. **Infrastructure Metrics**:
   - Redis connection metrics and operation latency
   - Prometheus target availability and scrape duration
   - Grafana datasource availability and API latency

These metrics need to be visualized in a standardized dashboard for operational monitoring.

## Dashboard Implementation Plan

### 1. Platform Health Overview Dashboard

A high-level dashboard showing the overall health of all services in the platform:

- **Health Status Panel**: Shows all services and their current health status (OK, DEGRADED, ERROR)
- **Degraded Services**: List of services currently in a degraded state, with time since degradation
- **Error Services**: List of services currently in an error state, with time since error
- **Overall Platform Health**: Percentage of healthy services vs total services

### 2. Database Health Dashboard

A detailed dashboard for database health metrics:

- **Connection Pool Status**: Current connections vs. max connections
- **Query Latency**: P95, P99 latency histograms for queries
- **Error Rates**: Error count per database service
- **Database-Specific Metrics**:
  - PostgreSQL: WAL lag, replication status
  - MySQL: Replication lag, table lock time
  - SQLite: Checksum verification status, write lock time

### 3. Infrastructure Health Dashboard

A dashboard for infrastructure service health:

- **Redis Health Panel**: Connection status, memory usage, operation latency
- **Prometheus Health Panel**: Target availability, scrape success rate, query latency
- **Grafana Health Panel**: Datasource availability, API latency

## Implementation Details

### Dashboard JSON Structure

Each dashboard will be defined in JSON format following Grafana's dashboard schema:

```json
{
  "annotations": {...},
  "editable": true,
  "gnetId": null,
  "graphTooltip": 0,
  "id": null,
  "links": [],
  "panels": [...],
  "refresh": "10s",
  "schemaVersion": 22,
  "style": "dark",
  "tags": ["platform-health"],
  "title": "Platform Health Overview",
  "uid": "platform-health",
  "version": 1
}
```

### Panel Types

1. **Status Panel**: To show service health state with color coding
   - Green: OK
   - Yellow: DEGRADED
   - Red: ERROR

2. **Gauge Panel**: For showing percentages (e.g., healthy services)

3. **Time-series Panel**: For latency metrics over time

4. **Stat Panel**: For point-in-time status values

5. **Table Panel**: For listing services with issues

### Alert Integration

The dashboards will integrate with existing Prometheus alerts:

- Visual indicators when alerts are firing
- Links to alert documentation
- Historical alert state visualization

## Dashboard Provisioning

The dashboards will be provisioned automatically using Grafana's provisioning system:

1. Store dashboard JSON files in `monitoring/grafana/dashboards/`
2. Create a dashboard provisioning config in `monitoring/grafana/provisioning/dashboards/`
3. Configure the Docker container to load these dashboards on startup

```yaml
# monitoring/grafana/provisioning/dashboards/platform.yaml
apiVersion: 1
providers:
  - name: 'Platform Dashboards'
    orgId: 1
    folder: 'Platform'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/dashboards
      foldersFromFilesStructure: true
```

## Testing

Each dashboard will be tested in the following scenarios:

1. **Normal Operation**: All services healthy
2. **Degraded State**: Some services in degraded state
3. **Error State**: Some services in error state
4. **Mixed State**: Combination of healthy, degraded, and error states

## Documentation

User documentation will be provided for interpreting the dashboards:

1. **Understanding Service Health States**: What each state means and typical causes
2. **Troubleshooting Guide**: How to respond to degraded or error states
3. **Dashboard Navigation**: How to drill down from overview to detailed metrics
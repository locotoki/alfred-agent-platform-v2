# Alfred Platform Monitoring Dashboards

This document provides an overview of the monitoring dashboards available in the Alfred Agent Platform, their purpose, and how to extend them.

## Dashboard Overview

The platform currently provides several Grafana dashboards:

### 1. Platform Overview Dashboard
- **Purpose**: High-level view of the entire platform's health and performance
- **Key Metrics**: Request rate, error rate, task processing time, memory and CPU usage
- **Target Audience**: DevOps and platform administrators
- **Location**: `/monitoring/grafana/dashboards/platform-overview.json`

### 2. Financial-Tax Agent Dashboard
- **Purpose**: Detailed metrics specific to the Financial-Tax agent
- **Key Metrics**: Task processing by intent, API request rate, error rates, resource usage
- **Target Audience**: Financial-Tax agent developers and maintainers
- **Location**: `/monitoring/grafana/dashboards/financial-tax-dashboard.json`

### 3. Service Health Dashboard
- **Purpose**: Comprehensive view of all service health statuses
- **Key Metrics**: Service availability, API response times, error rates, database health
- **Target Audience**: DevOps, SREs, and on-call engineers
- **Location**: `/monitoring/grafana/dashboards/service-health-dashboard.json`

### 4. Agent Comparison Dashboard
- **Purpose**: Side-by-side comparison of all agent performance
- **Key Metrics**: Task processing rates, success rates, intent distribution, resource usage
- **Target Audience**: Platform architects and engineers
- **Location**: `/monitoring/grafana/dashboards/agent-comparison-dashboard.json`

## Metrics Collection

All services expose metrics at the `/health/metrics` endpoint in Prometheus format. The key metrics currently collected include:

### System Metrics
- CPU and memory usage
- Container metrics
- Network metrics

### Application Metrics
- `http_requests_total` - HTTP request counts (with labels for status codes)
- `http_request_duration_seconds` - HTTP request latency
- `task_processing_total` - Task processing count by agent
- `tasks_completed_total` - Successful task completions by agent
- `tasks_failed_total` - Failed task completions by agent
- `task_processing_duration_seconds` - Task processing time (histogram)

### Agent-Specific Metrics
- `financial_tax_tasks_total` - Financial Tax agent task counts by intent
- `financial_tax_api_requests_total` - Financial Tax API requests
- `financial_tax_task_duration_seconds` - Financial Tax task duration

## Adding New Dashboards

To add a new dashboard:

1. Create a JSON dashboard definition in `/monitoring/grafana/dashboards/`
2. Import it to Grafana through the UI or restart Grafana to auto-import

## Extending Existing Dashboards

When extending dashboards:

1. Follow the naming conventions for metrics and labels
2. Ensure metrics are registered in agent code
3. Verify that metrics are being scraped by Prometheus
4. Test dashboards with different time ranges

## Alert Rules

The platform has two types of alert configurations:

1. **Basic Alerts** (`/monitoring/prometheus/alerts/basic.yml`)
   - Critical system-level alerts
   - Service availability alerts
   - High-level error rate alerts

2. **Extended Alerts** (`/monitoring/prometheus/alerts/extended.yml`)
   - More specific business logic alerts
   - Performance degradation alerts
   - Service-specific thresholds

## Future Dashboard Development

The current dashboards are focused on operational metrics. The planned Mission Control UI (Phase 6) will focus on business-level metrics and task management. Features will include:

- Real-time task status visualization
- Agent health indicators
- User-friendly views of task workflows
- Authentication and access control

## Dashboard Maintenance

Dashboards should be reviewed and updated:

- When new agents are added
- When new metrics are implemented
- After major platform architecture changes
- In response to incident investigations

## References

- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- [Grafana Documentation](https://grafana.com/docs/)
- [OpenTelemetry Integration](https://opentelemetry.io/)

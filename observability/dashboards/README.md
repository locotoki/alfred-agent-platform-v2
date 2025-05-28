# Grafana Dashboards

This directory contains Grafana dashboard JSON files for the GA-Hardening observability baseline.

## Available Dashboards

- **error_budget_burndown.json**: SLO error budget tracking
- **observability_v2_advanced.json**: Advanced system observability metrics
- **request_latency_hist.json**: Request latency histogram with p95 tracking

## Import Instructions

1. Access Grafana at http://localhost:3000 (default: admin/admin)
2. Navigate to Dashboards → Import
3. Upload JSON file or paste contents
4. Select Prometheus data source
5. Click Import

## Dashboard Requirements

All dashboards expect the following Prometheus metrics:
- `http_request_duration_seconds_bucket` (for latency)
- `container_restart_count_total` (for container health)
- `node_filesystem_*` (for disk usage)

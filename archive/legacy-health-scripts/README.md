# Legacy Health Check Scripts (Archived)

This directory contains health check scripts that were used before the standardization to healthcheck binary v0.4.0 across all services.

## Why Were These Scripts Archived?

As part of the health check standardization effort (v0.3.0-healthcheck-full), we moved all services to use the same:

1. Static healthcheck binary (v0.4.0) from `ghcr.io/alfred/healthcheck:0.4.0`
2. Standardized metrics port (9091) with `/metrics` endpoint
3. Consistent service_health Prometheus metric

This eliminated the need for service-specific health check scripts, patching, and custom implementations.

## New Approach

All health check related functionality is now handled through:

- `scripts/audit-health-binary.sh` - Identifies any Dockerfiles not using the latest healthcheck binary
- `scripts/bulk-update-health-binary.sh` - Updates Dockerfiles to use the latest healthcheck binary
- `scripts/ensure-metrics-exported.sh` - Verifies services are properly exporting metrics
- `scripts/update-healthcheck-binary.sh` - Updates the healthcheck binary across services

## Reference

These scripts are kept for historical reference only and should not be used anymore. See the health check standardization PR (#22) for details on the new approach.

Archived on: May 14, 2025
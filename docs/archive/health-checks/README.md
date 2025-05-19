# Health Checks Documentation Archive

This directory contains historical documents related to the health check implementation in the Alfred Agent Platform v2. These documents have been archived and replaced by more current documentation.

## Current Documentation

The following files are now the canonical sources for health check information:

- `/HEALTH-CHECKS-GUIDE.md` - Main guide in project root
- `/docs/operations/containerization/docker-compose-health-checks.md` - Detailed implementation guide
- `/docs/HEALTH_CHECK_STANDARD.md` - Standards definition (if it exists)

## Archived Documents

The following historical documents have been moved here for reference:

- Health check implementation summaries
- Health check assessment reports
- Compliance documentation
- Implementation plans
- Progress tracking

These documents trace the health check implementation journey and can be useful for understanding the project's evolution, but should not be considered current guidance.

## Health Check Structure

The platform now implements a standardized health check system across all services:

1. **Standard Endpoints**:
   - `/health` - Detailed health information
   - `/healthz` - Simple readiness probe
   - `/metrics` - Prometheus metrics

2. **Port Separation**:
   - Application port: Main service interface
   - Metrics port: Dedicated for Prometheus metrics (909x)

3. **Health Check Integration**:
   - Docker container health checks
   - Prometheus monitoring
   - Grafana dashboards

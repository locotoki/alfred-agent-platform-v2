# Health Check Bootstrap

This document outlines the implementation of the Phase 0 Health Check Bootstrap for the Alfred Agent Platform.

## Overview

The health check bootstrap implements a standardized health check system across all services in the platform using a static health checker binary. This approach ensures consistent health monitoring without requiring each container to have tools like `curl`, `wget`, or `nc` installed.

## Key Components

### 1. Static Health Checker Binary

A pre-built multi-architecture static binary (~8MB) for health checking has been integrated into all service Dockerfiles. This binary provides a unified interface for performing different types of health checks:

- HTTP endpoint checks: `healthcheck --http http://localhost:PORT/health`
- Redis connectivity: `healthcheck --redis redis://localhost:PORT`
- PostgreSQL connectivity: `healthcheck --postgres postgresql://user:pass@localhost:PORT/db`
- TCP port checks: `healthcheck --tcp localhost:PORT`
- Process existence: `healthcheck --process NAME`

### 2. Prometheus & Grafana Integration

The implementation includes:
- Prometheus configuration for service discovery and health monitoring
- Custom Grafana dashboards for visualizing health status
- Alerting rules for service availability

### 3. Standardized Docker Compose Configuration

All service health checks in `docker-compose-clean.yml` have been updated to use the static health checker binary with appropriate configurations based on service type.

## Implementation Files

### Scripts

- `/scripts/update-healthcheck-binary.sh` - Updates all service Dockerfiles to include the health checker binary
- `/scripts/setup-prometheus-health-checks.py` - Configures Prometheus for health monitoring
- `/scripts/seed-health-dashboard.py` - Creates Grafana dashboards for health visualization
- `/scripts/verify-service-health.sh` - Verifies service health status
- `/scripts/bootstrap-health-checks.sh` - Master script to orchestrate the entire bootstrap process

### Configurations

- `docker-compose-clean.yml` - Updated with standardized health check configurations
- `/monitoring/prometheus/prometheus.yml` - Prometheus configuration with service discovery
- `/monitoring/prometheus/rules/health_alerts.yml` - Health alerting rules

## Usage

### Running the Bootstrap

To bootstrap the health check system:

```bash
# Execute the bootstrap script
./scripts/bootstrap-health-checks.sh
```

This will:
1. Update all service Dockerfiles with the health checker binary
2. Configure Prometheus for health monitoring
3. Build and restart services with the new configurations
4. Seed Grafana dashboards for health visualization
5. Verify service health status

### Accessing Health Dashboards

After bootstrap, access the health dashboards at:

- URL: http://localhost:3005
- Default credentials: admin / admin (unless `MONITORING_ADMIN_PASSWORD` is set)

Available dashboards:
- Alfred Platform Health Status - Overall service health status
- Alfred Platform Health Metrics - Detailed health metrics

## Health Check Policy

The implementation follows these policies for internal service probes:

- **Redis**: PING commands allowed for lightweight health verification
- **PostgreSQL**: Basic connectivity checks only (pg_isready)
- **Vector DB (Qdrant)**: HTTP health endpoint checks
- **PubSub Emulator**: Basic port/endpoint checks
- **Model Services**: HTTP health endpoint checks only (no model loading)

## Grafana Authentication

Grafana admin credentials are supplied via the `MONITORING_ADMIN_PASSWORD` environment variable, which defaults to `admin` if not set. The bootstrap script and dashboard seeding use these credentials.

## Next Steps

1. **Testing**: Validate health check functionality across all services
2. **Performance Analysis**: Monitor the impact of health checks on system resources
3. **Alert Integration**: Connect alerts to notification channels
4. **Documentation**: Update operational documentation with health check procedures

---

## Technical Details

### Health Check Endpoints

All services now expose a `/health` endpoint that returns a simple status response:

```json
{
  "status": "healthy"
}
```

### Docker Compose Health Check Configuration

Example configuration:

```yaml
healthcheck:
  test: ["CMD", "healthcheck", "--http", "http://localhost:8080/health"]
  interval: 30s
  timeout: 20s
  retries: 5
  start_period: 45s
```

### Dockerfile Integration

The health checker binary is added to each service Dockerfile:

```dockerfile
FROM ghcr.io/alfred/healthcheck:0.3.1 AS healthcheck

FROM original-base-image

# ...

# Copy healthcheck binary
COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck

# ...
```
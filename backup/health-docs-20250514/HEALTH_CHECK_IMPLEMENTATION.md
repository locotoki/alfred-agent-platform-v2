# Health Check Implementation

This document describes the implementation of health checks for the Alfred Agent Platform v2 services.

## Overview

We've implemented the following changes to ensure all services comply with the health check standard defined in `docs/HEALTH_CHECK_STANDARD.md`:

1. Standardized health check endpoints:
   - `/health` for detailed service health information
   - `/healthz` for simple health probes
   - `/metrics` for Prometheus metrics

2. Updated Docker Compose configurations:
   - Consistent health check command: `healthcheck --http http://localhost:<PORT>/health`
   - Standard timing parameters: 30s interval, 20s timeout, 5 retries, 45s start period
   - Added `prometheus.metrics.port: "9091"` label for service discovery
   - Exposed port 9091 for metrics in all services

3. Service-specific implementations:
   - Added health wrappers for infrastructure services (Redis, PubSub)
   - Direct health check implementation for application services
   - Modified response formats to comply with the standard schema
   - Secondary metrics server on port 9091 using threading for FastAPI services

## Service Implementations

### Core Infrastructure Services

#### Redis

Redis doesn't provide HTTP endpoints by default, so we've added a wrapper service:

- Created a FastAPI-based health wrapper that runs alongside Redis
- Modified the Docker image to include both Redis and the health wrapper
- Exposed metrics on port 9091
- Updated health check to use the wrapper's endpoints

#### PubSub Emulator

Similar to Redis, the PubSub emulator needed a wrapper:

- Created a FastAPI-based health wrapper that checks PubSub functionality
- Modified the Docker image to run both the emulator and wrapper
- Exposed metrics on port 9091
- Updated health check to use the wrapper's endpoints

### Agent Services

#### Model Registry Service

Direct health check implementation:
- Added standard health endpoints to FastAPI application
- Dependency tracking for database connections
- Metrics server on port 9091
- Updated docker-compose.yml with port mapping and labels

#### Model Router Service

Direct health check implementation:
- Added standard health endpoints to FastAPI application
- Dependency tracking for model registry service
- Secondary metrics server on port 9091 using threading
- Updated docker-compose.yml with port mapping and labels

#### Agent Core Service

The agent core service now has a complete health check implementation:
- Created FastAPI application with standard health endpoints
- Added secondary metrics server on port 9091 using threading
- Added a dedicated job in prometheus.yml for agent-core metrics
- Standardized response formats according to the specification

The agent core library (`libs/agent_core/health`) provides:
- A factory function to create compliant health endpoints
- Standard dependency tracking functionality 
- Proper response formats according to the standard

#### Social Intelligence Agent

The Social Intel service now has proper health check implementations:
- Added a `/healthz` endpoint for simple health probes
- Integrated with circuit breaker patterns for dependency monitoring
- Returns standardized response formats

### UI Services

#### Mission Control (Admin UI)

Updated the health check configuration:

- Changed from `wget` to the standard `healthcheck` command
- Updated endpoint paths to comply with the standard
- Standardized timing parameters

#### UI Chat (Streamlit)

Fixed the health check configuration:

- Changed from `curl` direct calls to the standard `healthcheck` command
- Updated endpoint from `/healthz` to `/health` for consistency
- Standardized timing parameters

## Benefits of Implementation

The standardized health check implementation provides:

1. **Consistent monitoring**: All services can be monitored using the same tools and techniques
2. **Dependency tracking**: Services report their dependencies, enabling better troubleshooting
3. **Metrics integration**: Every service exposes metrics in a standard format
4. **Graceful degradation**: Services can report degraded status before failing completely

## Testing and Validation

To verify the implementation:

1. Run `docker-compose build redis pubsub-emulator` to build the updated services
2. Restart the services with `docker-compose restart redis pubsub-emulator`
3. Check their health status with `docker-compose ps`
4. Verify metrics with `curl http://localhost:9091/metrics` (for Redis) and `curl http://localhost:9092/metrics` (for PubSub)

## Prometheus Configuration

We've created a script to automatically configure Prometheus to collect metrics from all services:

1. Created `/scripts/healthcheck/update-prometheus-config.sh` to:
   - Scan Docker Compose files to find services exposing port 9091 (metrics port)
   - Update the Prometheus configuration with all discovered services
   - Create a unified job that collects metrics from all services
   - Maintain backwards compatibility with existing specialized jobs
   - Validate the configuration before applying changes

The script provides both automatic discovery and manual control:
- Maintains a base list of known services
- Adds any services with EXPOSE 9091 in their Dockerfiles
- Adds services from docker-compose.yml with port 9091 exposed
- Adds services from docker-compose override files

### Using the Script

To update the Prometheus configuration:

```bash
cd /home/locotoki/projects/alfred-agent-platform-v2
./scripts/healthcheck/update-prometheus-config.sh
```

The script will:
1. Create a new prometheus.yml.new file
2. Ask if you want to apply changes immediately
3. Restart Prometheus if changes are applied

## Next Steps

1. ✅ Implemented health checks for the following services:
   - agent-rag: Added metrics port mapping and proper labels
   - agent-financial: Added healthcheck binary usage and metrics export
   - agent-legal: Added healthcheck binary usage and metrics export
   - ui-chat: Added dedicated health server with FastAPI
   - ui-admin: Added Express.js health routes and metrics server
   
2. ✅ All core services now have standardized health checks!

2. For each service:
   - Choose appropriate implementation method (binary-based or direct)
   - Expose metrics port 9091 in docker-compose.yml
   - Add prometheus.metrics.port label
   - Update Prometheus configuration if needed

3. Post-implementation tasks:
   - ✅ Configure Prometheus to scrape metrics from all service endpoints
   - Create Grafana dashboards to visualize service health
   - Document service health metrics and alerts
   - Create alerting rules for service health degradation
   - Update runbooks with health check troubleshooting procedures

4. Validation and testing:
   - ✅ Updated Prometheus configuration to scrape all metrics endpoints
   - ✅ Implemented standardized port mapping (9091-9099) for all services
   - ✅ Added consistent healthcheck CMD commands using standardized binary
   - ✅ Added prometheus.metrics.port labels for service discovery
   - Create a comprehensive test script to validate all health endpoints
   - Test resilience of health checks during service degradation
# Alfred Agent Platform v2 - Service Containerization Guide

This document provides comprehensive information about the containerization of all services in the Alfred Agent Platform v2, with a focus on recent improvements and best practices.

## Overview

All services in the platform are containerized using Docker and orchestrated with Docker Compose. This approach ensures consistent deployments across environments and simplified service management.

## Service Containerization Status

| Service | Container Name | Base Image | Internal Port | External Port | Status |
|---------|---------------|------------|---------------|---------------|--------|
| Mission Control | mission-control | node:18-alpine | 3000 | 3007 | ✅ Completed |
| Social Intelligence | architect-api | python:3.11-slim | 9000 | 9000 | ✅ Completed |
| Financial-Tax | financial-tax | python:3.11-slim | 9003 | 9003 | ✅ Completed |
| Legal Compliance | legal-compliance | python:3.11-slim | 9002 | 9002 | ✅ Completed |
| Alfred Bot | alfred-bot | python:3.11-slim | 8011 | 8011 | ✅ Completed |

## Port Configuration

The platform uses standardized port assignments to avoid conflicts and ensure consistent access:

### UI Services
- **Mission Control UI**: Port 3007 (previously 3003)
- **Supabase Studio**: Port 3001
- **Grafana**: Port 3002

### Agent Services
- **Social Intelligence API**: Port 9000
- **Legal Compliance API**: Port 9002
- **Financial-Tax API**: Port 9003
- **Alfred Bot**: Port 8011

### Infrastructure Services
- **Supabase REST**: Port 3000
- **Prometheus**: Port 9090
- **Qdrant**: Ports 6333, 6334
- **Redis**: Port 6379
- **Pub/Sub Emulator**: Port 8085

## Recent Containerization Improvements

### Mission Control UI Containerization

The Mission Control UI service has been successfully containerized with the following improvements:

1. **Port Standardization**:
   - Changed from port 3003 to port 3007 for consistency
   - Updated all references in code and documentation

2. **Simplified Dockerfile**:
   - Single-stage build for better troubleshooting
   - Proper NODE_ENV and PORT settings
   - Exposed port 3000 internally, mapped to 3007 externally

3. **Docker Compose Integration**:
   - Added proper service dependencies
   - Configured volume mounts for development
   - Set up health checks for reliability

4. **Environment Variables**:
   - Standardized environment variables
   - Added proper service URLs for inter-service communication
   - Set consistent API endpoints

### Inter-Service Communication Improvements

To ensure reliable communication between containerized services:

1. **Network Configuration**:
   - All services on same Docker network (`alfred-network`)
   - Service discovery using container names as hostnames
   - Consistent internal and external port mapping

2. **API Proxying**:
   - Mission Control proxies requests to agent services
   - Fallback mechanisms for development and testing
   - Error handling for service unavailability

3. **Shared Libraries**:
   - Enhanced stub implementations for library dependencies
   - Fixed imports and implementations in shared libraries
   - Added missing methods and classes to support all services

## Docker Compose Configuration

The platform uses a modular Docker Compose configuration:

1. **Base Configuration**: `docker-compose.yml`
   - Contains all core infrastructure services
   - Defines networks and shared volumes
   - Configures environment variables

2. **Service-Specific Overrides**:
   - `docker-compose.override.mission-control.yml`
   - `docker-compose.override.storage.yml`
   - Additional overrides as needed

## Starting Containers

### Full Platform Startup
```bash
docker-compose up -d
```

### Individual Service Startup
```bash
# Mission Control UI
bash services/mission-control/start-container.sh

# Social Intelligence Agent
docker-compose up -d architect-api

# Financial-Tax Agent
docker-compose up -d financial-tax

# Legal Compliance Agent
docker-compose up -d legal-compliance
```

## Development with Containers

For development, containers are configured with volume mounts to allow real-time code changes:

```yaml
volumes:
  - ./services/mission-control/public:/app/public
  - ./services/mission-control/src:/app/src
  - mission-control-node-modules:/app/node_modules
```

This enables:
- Code changes without container rebuilds
- Immediate visibility of changes in development
- Preservation of node_modules between container restarts

## Troubleshooting Container Issues

Common issues and solutions:

1. **Container fails to start**:
   - Check Docker logs: `docker logs <container-name>`
   - Verify port availability: `netstat -tulpn | grep <port>`
   - Ensure dependencies are running: `docker-compose ps`

2. **Inter-service communication failure**:
   - Verify service health endpoints
   - Check environment variables for correct service URLs
   - Validate network connectivity between containers

3. **Volume mount issues**:
   - Ensure correct paths in docker-compose files
   - Check file permissions
   - Verify volume definitions and drivers

## Best Practices

1. **Port Standardization**:
   - Use consistent ports across environments
   - Document all port assignments
   - Update all code references when changing ports

2. **Container Health Checks**:
   - Implement health check endpoints in all services
   - Configure container health checks
   - Use health checks for service dependencies

3. **Environment Configuration**:
   - Use environment variables for configuration
   - Provide defaults for development
   - Document all required variables

4. **Documentation**:
   - Update documentation when changing container configurations
   - Document startup procedures
   - Include troubleshooting steps

## Conclusion

The Alfred Agent Platform v2 is now fully containerized, with all services running in Docker containers and communicating reliably. Recent improvements to the Mission Control UI containerization and inter-service communication have enhanced the platform's reliability and consistency.

---

*Document last updated: May 6, 2025*

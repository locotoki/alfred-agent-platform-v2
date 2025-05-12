# Docker Compose Optimization Plan

This document outlines a comprehensive plan to optimize and standardize Docker Compose configurations across the Alfred Agent Platform v2 project.

## Current State

The repository contains over 30 Docker Compose files with various purposes:

1. **Base configurations**:
   - `docker-compose.yml` - Original base configuration
   - `docker-compose.unified.yml` - Improved unified configuration

2. **Environment-specific configurations**:
   - `docker-compose.dev.yml` - Development-specific overrides
   - `docker-compose.prod.yml` - Production-specific overrides

3. **Component-specific configurations**:
   - `docker-compose.agents.yml` - Agent services
   - `docker-compose.core.yml` - Core infrastructure
   - `docker-compose.ui.yml` - UI services
   - `docker-compose.monitoring.yml` - Monitoring services

4. **Special-purpose configurations**:
   - Various legacy files with specific purposes
   - `docker-compose.override.*.yml` files for specific service overrides

The current state presents several challenges:

- **Configuration sprawl**: Too many files, causing confusion
- **Inconsistent naming**: Different conventions across files
- **Duplication**: Same services defined in multiple files with different settings
- **Health check inconsistencies**: Different approaches to health monitoring
- **Resource management gaps**: Inconsistent resource constraints

## Optimization Goals

1. **Simplify file structure**: Create a minimal set of well-organized files
2. **Standardize configurations**: Consistent naming, health checks, and dependencies
3. **Improve resource utilization**: Add appropriate resource constraints to all services
4. **Enhance maintainability**: Clear organization, comments, and documentation
5. **Support multiple environments**: Development, testing, and production

## Implementation Plan

### 1. Create a New Unified Structure

We will create a new, structured approach using these files:

- `docker-compose.yml` - Base configuration with **all** services defined
- `docker-compose.dev.yml` - Development-specific overrides (bind mounts, debug flags)
- `docker-compose.prod.yml` - Production-specific overrides (resource limits, security)
- `docker-compose.local.yml` - Local development specifics (port mappings, stub services)
- `docker-compose.test.yml` - Testing-specific overrides (test containers, coverage tools)

### 2. Standardize Service Definitions

For each service, standardize:

- **Naming**: Use consistent naming conventions (e.g., `agent-core`, `db-postgres`)
- **Image Sources**: Clear, versioned image references
- **Health Checks**: Standardized checks with appropriate timeouts and retries
- **Resource Limits**: Appropriate CPU and memory constraints
- **Dependencies**: Clear, explicit service dependencies
- **Networks**: Consistent network configuration
- **Volumes**: Named volumes with clear purposes

### 3. Create Service Groupings

Organize services into logical groups with shared configuration:

- **Core Infrastructure**: Redis, Vector DB, PubSub Emulator
- **Database Services**: PostgreSQL, Auth, API, Admin, Storage
- **Agent Services**: Core, RAG, Atlas, domain-specific agents
- **UI Services**: Chat UI, Admin Dashboard, Auth UI
- **LLM Services**: Model Registry, Model Router, Ollama
- **Monitoring Services**: Prometheus, Grafana, Exporters
- **Supporting Services**: Mail Server, etc.

### 4. Implement Environment-Specific Configurations

Customize for different environments while maintaining consistency:

- **Development**: Bind mounts, debug logging, hot reloading
- **Production**: Resource limits, security hardening, persistence
- **Testing**: Test-specific services, coverage monitoring

### 5. Create Helper Scripts

Provide scripts to simplify usage:

- `start-platform.sh` - Start the platform with appropriate overrides
- `stop-platform.sh` - Stop all services gracefully
- `monitor-platform.sh` - View platform status and health
- `platform-logs.sh` - Consolidated log viewing

## Technical Improvements

### 1. Health Check Standardization

All services will have consistent health checks with:

- Appropriate test commands (using `wget`, `curl`, or process checks)
- Reasonable timeouts and retry settings
- Start periods appropriate to service startup times

### 2. Resource Management

All services will have appropriate resource constraints:

- Memory limits to prevent container OOM issues
- CPU limits to ensure fair resource sharing
- Reservations for critical services

### 3. Dependency Management

Explicit dependencies will be defined with appropriate conditions:

- `service_healthy` for services with health checks
- `service_started` for services without health checks
- Proper ordering to minimize startup issues

### 4. Network Configuration

Standardized network configuration:

- Single shared network (`alfred_network`)
- Consistent port mappings
- Appropriate service discovery via DNS

### 5. Volume Management

Improved volume management:

- Named volumes for all persistent data
- Consistent naming conventions
- Appropriate access permissions

## Migration Path

To migrate from the current state to the optimized configuration:

1. **Create new files**: Develop the new configuration files
2. **Test thoroughly**: Verify that all services start and operate correctly
3. **Document changes**: Create comprehensive documentation
4. **Update scripts**: Update all scripts that use Docker Compose
5. **Phase out old files**: Gradually deprecate and remove old configurations

## Timeline

1. **Phase 1**: Create and test base configuration (1-2 days)
2. **Phase 2**: Implement environment-specific configurations (1-2 days)
3. **Phase 3**: Develop helper scripts (1 day)
4. **Phase 4**: Test and refine (1-2 days)
5. **Phase 5**: Documentation and cleanup (1 day)

## Success Criteria

The optimization will be considered successful when:

1. All services start correctly with a single command
2. Resource utilization is improved
3. Configuration files are clear and well-documented
4. Different environments are supported with minimal configuration changes
5. The number of Docker Compose files is reduced by at least 75%

## Conclusion

This optimization plan will significantly improve the Docker Compose configuration for the Alfred Agent Platform v2, making it more maintainable, efficient, and easier to use across different environments.
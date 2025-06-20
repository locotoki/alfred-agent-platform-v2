# Docker Compose Evolution History

This document captures the history of changes to the Docker Compose configuration and containerization efforts in the Alfred Agent Platform.

## Structure Cleanup (May 2025)

The Docker Compose configuration was simplified with these changes:

1. **Removed Multiple Override Files:**
   - Backed up and removed all `docker-compose.override.*.yml` files
   - Consolidated relevant settings into `docker-compose.dev.yml`

2. **Introduced Service Profiles:**
   - Added `dev` profile for development services
   - Added `mocks` profile for mock services
   - Added `prod` profile for production services

3. **Created Personal Configuration Template:**
   - Added `docker-compose.local.yml.template` for developer-specific settings
   - Updated `.gitignore` to ensure `docker-compose.local.yml` is not committed

4. **Files Removed:**
   - `docker-compose.override.mission-control.dev.yml`
   - `docker-compose.override.mission-control.yml`
   - `docker-compose.override.simplified-mc.yml`
   - `docker-compose.override.storage.yml`
   - `docker-compose.override.ui-chat.yml`
   - `docker-compose.override.yml`

## Mission Control Containerization

### Background

The Mission Control service was initially running directly on the host system, while other services were properly containerized. This caused issues with:

1. **Inconsistent Deployment Model**: Different approaches for different services
2. **Port Configuration Complexity**: Conflicts between configured and actual ports
3. **Environment Inconsistency**: Different settings between environments
4. **Missing Service Dependencies**: Proper dependency management was lacking

### Implementation

1. **Added to docker-compose.yml**:
   ```yaml
   mission-control:
     build:
       context: .
       dockerfile: ./services/mission-control/Dockerfile
     container_name: mission-control
     depends_on:
       supabase-db:
         condition: service_healthy
       architect-api:
         condition: service_healthy
     ports:
       - "3007:3000"
     environment:
       - NODE_ENV=${NODE_ENV:-development}
       - SOCIAL_INTEL_URL=http://architect-api:9000
       - FINANCIAL_TAX_URL=http://financial-tax:9003
     volumes:
       - ./services/mission-control/public:/app/public
       - ./services/mission-control/src:/app/src
       - mission-control-node-modules:/app/node_modules
     healthcheck:
       test: ["CMD", "wget", "-qO-", "http://localhost:3000/api/health"]
       interval: 30s
       timeout: 10s
       retries: 3
   ```

2. **Updated Dockerfile**:
   - Corrected port exposure
   - Improved environment configuration

3. **Benefits**:
   - Consistent deployment model across all services
   - Simplified configuration using Docker network hostnames
   - Improved portability and dependency management
   - Better development experience with consistent environments

## Health Check Improvements

### Problem Statement

Many services were using a non-existent `healthcheck` binary in their Docker health check configurations, resulting in health checks failing and services being reported as unhealthy.

### Changes Made

1. **Replaced Non-Existent Binary**:
   - HTTP endpoints: Using `curl -f http://localhost:<PORT>/health`
   - TCP endpoints: Using `nc -z localhost <PORT>` or `curl -f telnet://localhost:<PORT>`
   - Redis: Using `curl -f http://localhost:9091/health` (via health wrapper)
   - PostgreSQL: Using `pg_isready` which is included in the postgres container

2. **Files Updated**:
   - `docker-compose.yml` - Main configuration file
   - `docker-compose.override.ui-chat.yml` - UI Chat override file
   - `docker-compose-clean.yml` - Cleaned version of the main docker-compose file

3. **Affected Services**:
   - All core services including Redis, Vector DB, Model Registry
   - All agent services including Agent Core, Agent RAG, Social Intelligence
   - UI services including UI Chat and Auth UI

### Implementation Example

From:
```yaml
healthcheck:
  test: ["CMD", "healthcheck", "--http", "http://localhost:8079/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

To:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8079/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

## Evolution Timeline

| Date | Change | Description |
|------|--------|-------------|
| Early 2025 | Initial Docker Compose | Basic containerization of services |
| March 2025 | Mission Control Containerization | Added Mission Control to Docker Compose |
| April 2025 | Health Check Fixes | Fixed health check configurations |
| May 2025 | Docker Compose Restructuring | Simplified file structure and introduced profiles |

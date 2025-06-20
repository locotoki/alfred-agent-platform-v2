# Mission Control Containerization Plan

This document outlines the plan to containerize the Mission Control service for consistency with the other services in the Alfred Agent Platform.

## Current Status

- Most services in the Alfred Agent Platform are running as Docker containers (architect-api, financial-tax, etc.)
- The Mission Control service is running directly on the host on port 3007
- The Mission Control Dockerfile exists but is not being used in the docker-compose.yml file

## Issues with Current Setup

1. **Inconsistent Deployment Model**: While other services are properly containerized, the Mission Control UI is running directly on the host.

2. **Port Configuration Complexity**: We recently had to fix port conflicts because the service was configured to use port 3003 but was actually running on port 3007.

3. **Environment Inconsistency**: Local development setup may differ from what would be used in production.

4. **Missing Service Dependencies**: Service dependencies and health checks aren't properly defined.

## Containerization Plan

### 1. Add Mission Control to docker-compose.yml

Create a new service entry for mission-control in docker-compose.yml:

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
      - NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL:-http://localhost:3007}
      - NEXT_PUBLIC_SUPABASE_URL=${NEXT_PUBLIC_SUPABASE_URL:-http://localhost:3000}
      - NEXT_PUBLIC_SUPABASE_ANON_KEY=${ANON_KEY}
      - SOCIAL_INTEL_URL=http://architect-api:9000
      - FINANCIAL_TAX_URL=http://financial-tax:9003
      - LEGAL_COMPLIANCE_URL=http://legal-compliance:9002
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

### 2. Update Dockerfile

Update the Dockerfile to expose the correct port and set up the necessary environment:

```Dockerfile
# Update the EXPOSE line to match the expected port
EXPOSE 3000
```

### 3. Add Volume for node_modules

Add a named volume for node_modules to the volumes section:

```yaml
volumes:
  mission-control-node-modules:
```

### 4. Update PORT-CONFIGURATION.md

Update the port configuration documentation to reflect that mission-control will be running in a Docker container on port 3007 externally, mapping to port 3000 internally.

### 5. Update .env Configuration

Ensure all necessary environment variables are properly set in the .env file and documented.

## Implementation Steps

1. Stop the currently running mission-control service on the host
2. Add the mission-control service to docker-compose.yml
3. Add mission-control-node-modules to the volumes section
4. Build and start the containerized mission-control service
5. Verify that the service is accessible at http://localhost:3007
6. Verify that the service can properly communicate with other services

## Expected Benefits

1. **Consistency**: All services will follow the same deployment model
2. **Simplified Configuration**: Service URLs will use the Docker network hostnames
3. **Portability**: The entire platform can be deployed with a single `docker-compose up` command
4. **Better Dependency Management**: Service dependencies are properly defined
5. **Improved Development Experience**: Consistent development and production environments

## Potential Challenges

1. **Inter-Service Communication**: May need to adjust how mission-control communicates with other services
2. **Environment Variables**: Need to ensure all required environment variables are properly set
3. **Volume Mounting**: May need to adjust how files are mounted for development

## Conclusion

Containerizing the mission-control service will bring consistency to the Alfred Agent Platform and eliminate the port configuration issues we've been facing. This change aligns with the overall architecture of the platform and will make future deployments more reliable.

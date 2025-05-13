# Unified Docker Compose Configuration

This document provides information about the unified Docker Compose setup that consolidates all services from the Alfred Agent Platform v2 into a single, cohesive configuration.

## Overview

The unified Docker Compose configuration (`docker-compose.unified.yml`) centralizes all services into a single file with consistent naming, health checks, network configuration, and dependencies. This simplifies platform deployment and management while improving reliability.

## Services Organization

Services are organized into logical groups:

1. **Core Infrastructure**
   - Redis - In-memory data store
   - Vector-DB (Qdrant) - Vector database for embeddings
   - PubSub Emulator - Message queue for service communication
   - LLM Service (Ollama) - Local LLM inference

2. **LLM Infrastructure**
   - Model Registry - Manages available LLM models
   - Model Router - Routes LLM requests to appropriate backend

3. **Database Services (Supabase)**
   - DB Postgres - PostgreSQL database
   - DB Auth - Database authentication service
   - DB API - Database REST API
   - DB Admin - Database admin UI
   - DB Realtime - Database realtime updates
   - DB Storage - Database storage

4. **Agent Services**
   - Agent Core - Core agent service
   - Agent RAG - RAG service
   - Agent Atlas - Atlas agent
   - Agent Social - Social intelligence agent
   - Agent Financial - Financial tax agent
   - Agent Legal - Legal compliance agent

5. **UI Services**
   - UI Chat - Chat UI
   - UI Admin - Admin dashboard
   - Auth UI - Authentication UI

6. **Monitoring Services**
   - Monitoring Metrics - Prometheus metrics collection
   - Monitoring Dashboard - Grafana dashboard
   - Monitoring Node - Host metrics exporter
   - Monitoring DB - Database metrics exporter
   - Monitoring Redis - Redis metrics exporter

7. **Mail Services**
   - Mail Server - Local mail server (MailHog)

## Improvements

1. **Standardized Health Checks**
   - Every service has a properly configured health check
   - Consistent retry and timeout settings
   - Process-based health checks for stub services

2. **Dependency Management**
   - Clear dependency chain between services
   - Services wait for their dependencies to be healthy before starting
   - Proper startup sequence to avoid cascading failures

3. **Network Configuration**
   - All services use a shared `alfred-network` (external network)
   - Consistent port mapping with minimal conflicts
   - Clear labeling for service discovery

4. **Volume Management**
   - Named volumes for all persistent data
   - Clear organization and naming conventions

5. **Environment Variables**
   - Consistent environment variable naming
   - Default values provided for easier setup
   - Support for external configuration

6. **Stub Services**
   - Alpine-based stubs for development
   - Can be replaced with real service implementations as needed
   - Proper health checks for stub services

## Usage

### Starting the Platform

Use the provided `restart-all-containers.sh` script to manage the platform:

```bash
# Make the script executable (if needed)
chmod +x restart-all-containers.sh

# Start all services
./restart-all-containers.sh
```

The script will:
1. Stop and remove any existing containers
2. Create the required network if it doesn't exist
3. Create required volumes if they don't exist
4. Start all services in the correct order
5. Display container status and health information
6. Verify core services are operational

### Accessing Services

- Web UI: http://localhost:8502
- Admin Dashboard: http://localhost:3007
- Monitoring Dashboard: http://localhost:3005 (admin/admin)
- Mail Interface: http://localhost:8025
- LLM API: http://localhost:11434

### Container Management

Check container status:
```bash
docker ps
```

View container logs:
```bash
docker logs <container-name>
```

Restart a specific container:
```bash
docker restart <container-name>
```

Access a container's shell:
```bash
docker exec -it <container-name> sh
```

## Migrating from Old Setup

To migrate from the old configuration:

1. Make sure you have the latest code:
   ```bash
   git pull
   ```

2. Run the restart script:
   ```bash
   ./restart-all-containers.sh
   ```

## Development vs Production

For development, the current configuration uses stub services for faster startup and lower resource usage. For production, you should:

1. Replace Alpine stubs with real service implementations
2. Configure proper API keys and credentials
3. Enable TLS/SSL for secure communication
4. Set up proper user authentication
5. Consider resource limits and scaling

## Troubleshooting

### Container Health Issues

If containers are showing as "unhealthy":

1. Check the container logs:
   ```bash
   docker logs <container-name>
   ```

2. Verify the health check command:
   ```bash
   docker inspect <container-name> | grep -A 10 "Healthcheck"
   ```

3. Try restarting the container:
   ```bash
   docker restart <container-name>
   ```

### Network Issues

If services can't communicate:

1. Verify the network exists:
   ```bash
   docker network ls
   ```

2. Inspect network connections:
   ```bash
   docker network inspect alfred-network
   ```

3. Test connectivity from within a container:
   ```bash
   docker exec -it <container-name> ping <other-container-name>
   ```

### Resource Issues

If containers are crashing due to resource constraints:

1. Check system resources:
   ```bash
   docker stats
   ```

2. Consider adjusting resource limits in the Docker Compose file

## Contributing

When adding new services to the unified Docker Compose file:

1. Follow the established naming conventions
2. Add appropriate health checks
3. Configure proper dependencies
4. Use the existing network
5. Add labels for service discovery
6. Document the new service

## Future Improvements

1. Add support for scaling agent services
2. Implement service discovery for dynamic scaling
3. Add support for TLS/SSL
4. Improve monitoring and alerting
5. Add support for container orchestration tools (Kubernetes)
# Docker Setup Guide

This document provides detailed information about the optimized Docker Compose setup for Alfred Agent Platform v2.

## Overview

The platform now uses a streamlined Docker Compose configuration with modular environment-specific overrides:

1. `docker-compose-clean.yml` - Base configuration with all services (without resource constraints)
2. `docker-compose/docker-compose.dev.yml` - Development-specific overrides
3. `docker-compose/docker-compose.prod.yml` - Production-specific overrides

Note: For compatibility reasons, we've removed resource constraints from the Docker Compose files. If you need resource constraints, you can add them back in your local deployment.

This approach offers several benefits:
- Consistent configuration across environments
- Clear separation of environment-specific settings
- Standardized health checks and resource limits
- Simplified service management

## Quick Start

Use the provided script to start the platform with a single command:

```bash
# Make the script executable (if needed)
chmod +x start-platform.sh

# Start all services in development mode
./start-platform.sh

# Start all services in production mode
./start-platform.sh -e prod

# Start specific services only
./start-platform.sh agent-core ui-chat

# View logs for specific services
./start-platform.sh -a logs agent-core
```

## Key Features

### Standardized Service Definitions

All services now have:
- Consistent naming conventions
- Well-defined health checks
- Appropriate resource constraints
- Explicit dependencies
- Clear organization with labels

### Improved Resource Management

Services are configured with appropriate resource limits:
- Small services: 150MB memory, 0.3 CPU
- Medium services: 300MB memory, 0.5 CPU
- Large services: 500MB memory, 1.0 CPU

Production environment uses higher limits to ensure performance under load.

### Enhanced Health Monitoring

All services implement standardized health checks with:
- Appropriate test commands
- Reasonable intervals and timeouts
- Sufficient start periods

### Logical Service Grouping

Services are organized into logical groups:
- Core Infrastructure: Redis, Vector DB, PubSub, etc.
- Database Services: PostgreSQL, Auth, API, etc.
- Agent Services: Core, RAG, Atlas, etc.
- UI Services: Chat UI, Admin Dashboard, Auth UI
- LLM Services: Model Registry, Model Router, etc.
- Monitoring Services: Prometheus, Grafana, etc.

## Key Services

The platform includes the following key service groups:

1. **Core Infrastructure**
   - Redis, Vector-DB (Qdrant), PubSub Emulator, LLM Service (Ollama)

2. **LLM Infrastructure**
   - Model Registry, Model Router

3. **Database Services (Supabase)**
   - DB Postgres, DB Auth, DB API, DB Admin, DB Realtime, DB Storage

4. **Agent Services**
   - Agent Core, Agent RAG, Agent Atlas, Agent Social, Agent Financial, Agent Legal

5. **UI Services**
   - UI Chat, UI Admin, Auth UI

6. **Monitoring Services**
   - Prometheus, Grafana, Node Exporter, Postgres Exporter, Redis Exporter

7. **Mail Services**
   - Mail Server (MailHog)

## Access URLs

Once the platform is running, you can access various services at:

- **Web UI**: http://localhost:8502
- **Admin Dashboard**: http://localhost:3007
- **Monitoring Dashboard**: http://localhost:3005 (admin/admin)
- **Mail Interface**: http://localhost:8025 (in development)
- **LLM API**: http://localhost:11434

## Environment Variables

The following environment variables can be set to customize the platform:

| Variable | Description | Default |
|----------|-------------|---------|
| `ALFRED_ENVIRONMENT` | Environment (development, production) | development |
| `ALFRED_DEBUG` | Enable debug mode | true |
| `DB_USER` | Database username | postgres |
| `DB_PASSWORD` | Database password | your-super-secret-password |
| `DB_NAME` | Database name | postgres |
| `DB_JWT_SECRET` | JWT secret for database | your-super-secret-jwt-token |
| `ALFRED_OPENAI_API_KEY` | OpenAI API key | sk-mock-key-for-development-only |
| `ALFRED_ANTHROPIC_API_KEY` | Anthropic API key | |
| `ALFRED_YOUTUBE_API_KEY` | YouTube API key | youtube-mock-key-for-development-only |
| `MONITORING_ADMIN_PASSWORD` | Grafana admin password | admin |
| `ALFRED_PROJECT_ID` | Project ID for PubSub emulator | alfred-agent-platform |

## Development vs. Production

### Development Environment

The development environment prioritizes ease of development:
- Bind mounts for hot reloading
- Verbose logging
- Debug-friendly configurations
- Local stub services
- Generous timeouts

### Production Environment

The production environment focuses on security and performance:
- Secure default configurations
- Resource limits for stability
- Minimal exposed ports
- Real (non-stub) services
- Performance-optimized settings

## Troubleshooting

### Health Check Failures

If a service is marked as unhealthy:
1. Check the logs: `docker logs <container-name>`
2. Verify the health check command: `docker inspect <container-name> | grep -A 10 "Healthcheck"`
3. Try restarting the service: `docker restart <container-name>`

### Service Dependencies

If services are not starting in the correct order:
1. Check the dependencies in the Docker Compose files
2. Verify the health check configurations
3. Try starting the dependent services manually first

### Resource Issues

If containers are crashing due to resource constraints:
1. Check current resource usage: `docker stats`
2. Adjust the resource limits in the Docker Compose files
3. Ensure your host has sufficient resources

## Migration from Legacy Setup

To migrate from the legacy Docker Compose setup:

1. Stop any running containers:
   ```bash
   docker-compose down
   ```

2. Start using the new optimized setup:
   ```bash
   ./start-platform.sh
   ```

## Volume Management

The Alfred Agent Platform uses Docker volumes to persist data between container restarts. This section explains how volumes are managed and provides guidance on data preservation.

### Critical Data Volumes

The following volumes contain important data that should be preserved:

| Volume Name | Contents | Impact if Lost |
|-------------|----------|----------------|
| alfred-db-postgres-data | PostgreSQL database tables and records | All application state, user data, and authentication information |
| alfred-vector-db-data | Vector embeddings and collections | All RAG data and vector search capabilities |
| alfred-redis-data | Cache and message queue data | Temporary disruption of services |
| alfred-llm-service-data | Local LLM models and inference data | Models will need to be redownloaded |
| alfred-db-storage-data | Storage files | Uploaded files and attachments |

> Note: If you're migrating from an older version of the platform, your volumes may have names like `alfred-agent-platform-v2_postgres-data`. Use the `migrate-volumes.sh` script to migrate data to the new naming convention.

### Volume Operations

The platform includes tools to manage volumes safely:

1. **Starting Services**:
   - Normal operation: `./start-platform.sh up dev`
   - When started, containers will mount the volumes and use existing data

2. **Stopping Services**:
   - Without removing volumes: `./start-platform.sh down`
   - With removing volumes (CAUTION): `./start-platform.sh down -c`

3. **Volume Cleanup**:
   - For removing orphaned volumes: `./cleanup-volumes.sh`
   - This script provides options to clean up only anonymous volumes or all orphaned volumes

### Data Preservation and Migration

The optimized Docker Compose file (`docker-compose-clean.yml`) uses a consistent volume naming convention:

1. All volume names now follow the pattern `alfred-[service]-data`
2. This makes it clear which volumes belong to which services
3. The naming is consistent across all environments (dev, prod)

#### Volume Migration

If you're coming from a previous version of the platform, you'll need to migrate your data:

1. **Identify existing volumes**: These typically have names like `alfred-agent-platform-v2_postgres-data`
2. **Run migration script**: Use `./migrate-volumes.sh` to copy data to the new volumes
3. **Verify migration**: Start the platform and check that your data is intact
4. **Clean up old volumes**: Once verified, you can remove the old volumes with `./cleanup-volumes.sh`

The migration script handles all the complexity of copying data between volumes while maintaining data integrity.

### Important Notes

- **NEVER** use the `-c` flag in production without a proper backup
- Data in volumes persists until the volume is explicitly removed
- Changes made to data while containers are running are saved to the volumes
- Anonymous volumes (with random hash names) are typically safe to remove with the cleanup script

## Further Resources

- For detailed script usage, run: `./start-platform.sh --help`
- To view the full Docker Compose configuration, see: `docker-compose-clean.yml`
- For environment-specific overrides, see files in the `docker-compose/` directory
- For volume management:
  - `./migrate-volumes.sh` - Migrate data from old volumes to new consistently named volumes
  - `./cleanup-volumes.sh` - Clean up orphaned volumes safely

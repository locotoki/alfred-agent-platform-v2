# Development Environment Setup Guide

## Overview
This guide provides instructions for setting up a fully functional development environment for the Alfred Agent Platform v2.

## Prerequisites
- Docker and Docker Compose installed
- At least 8GB of RAM available for Docker
- Git installed
- Basic understanding of Docker and containerized applications

## Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/locotoki/alfred-agent-platform-v2.git
cd alfred-agent-platform-v2
```

### 2. Set Up Environment Variables
Copy the example environment file and update with your values:
```bash
cp .env.example .env
# Edit .env with your specific values
```

### 3. Start the Environment
```bash
# Pull pre-built images
docker compose pull

# Start all services
docker compose up -d

# Check service status
docker compose ps
```

## Port Allocations

The following ports are allocated to services:

### Core Services
- **PostgreSQL**: 5432
- **Redis**: 6379
- **Prometheus**: 9090
- **Grafana**: 3005 (mapped from internal 3000)

### Application Services
- **db-api**: 3000
- **db-admin**: 3001 (mapped from internal 3000)
- **slack_mcp_gateway**: 3010 (mapped from internal 3000)
- **slack-adapter**: 3011 (mapped from internal 8000)
- **agent-atlas**: 8000
- **hubspot-mock**: 8088 (mapped from internal 8000)
- **agent-social**: 9000
- **agent-core**: 8011

### Supporting Services
- **mail-server**: 1025 (SMTP), 8025 (Web UI)
- **pubsub-emulator**: 8085
- **vector-db**: 6333-6334
- **llm-service**: 11434

## Service Health Checks

The environment includes comprehensive health checks for all services. To view health status:

```bash
# View all service statuses
docker compose ps

# Check specific service logs
docker logs <service-name>

# Monitor health in real-time
watch docker compose ps
```

## Override Files

The development environment uses several override files for different purposes:

### docker-compose.override.yml
Main override file with development-specific configurations and health check adjustments.

### docker-compose.override.health-fixes.yml
Specific health check fixes for services that need custom health check configurations.

### docker-compose.override.dev-stubs.yml
Development stubs for services that don't have full implementations yet.

To use specific override files:
```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
```

## Troubleshooting

### Service Won't Start
1. Check logs: `docker logs <service-name>`
2. Verify port availability: `netstat -tulpn | grep <port>`
3. Ensure sufficient resources: `docker system df`

### Health Check Failures
1. Some services take time to initialize (especially llm-service)
2. Check service-specific health endpoints
3. Review health check configurations in override files

### Database Connection Issues
If services can't connect to databases:
```bash
# Create missing databases
docker exec db-postgres psql -U postgres -c "CREATE DATABASE auth_db;"
```

### Port Conflicts
All port conflicts have been resolved in the main configuration. If you encounter new conflicts:
1. Check PORT-ALLOCATION.md for current assignments
2. Update docker-compose.yml with new port mapping
3. Document the change

## Development Workflow

### Starting Fresh
```bash
# Complete clean start
docker compose down --volumes --remove-orphans
docker compose up --build -d
```

### Updating Services
```bash
# Pull latest changes
git pull origin main

# Rebuild specific service
docker compose build <service-name>

# Restart service
docker compose restart <service-name>
```

### Viewing Logs
```bash
# Follow logs for all services
docker compose logs -f

# View logs for specific service
docker compose logs -f <service-name>
```

## Service Status Summary

As of the latest test, the environment achieves:
- **39 total services** running
- **13 healthy services** (core infrastructure)
- **Port conflicts**: 0 (all resolved)
- **Core platform status**: Fully operational

## Next Steps

1. **For Developers**:
   - Set up your IDE with the project
   - Review service-specific documentation in `/services/<service-name>/README.md`
   - Check the API documentation in `/docs/api/`

2. **For DevOps**:
   - Review monitoring dashboards at http://localhost:3005
   - Set up alerts in Prometheus
   - Configure backup strategies

3. **For Testing**:
   - Run the test suite: `make test`
   - Check integration test documentation
   - Set up end-to-end testing environment

## Contributing

When making changes to the development environment:
1. Update this documentation
2. Test changes with a cold start
3. Verify no new port conflicts
4. Update PORT-ALLOCATION.md if adding new services
5. Create a PR with clear description of changes

## Support

For issues or questions:
1. Check existing GitHub issues
2. Review troubleshooting section above
3. Contact the development team in Slack #alfred-dev channel

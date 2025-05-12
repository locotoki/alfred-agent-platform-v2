# Alfred Agent Platform v2

A modular, Docker-based platform for AI agents and services.

## Overview

The Alfred Agent Platform is a comprehensive system for deploying and managing AI agents and services. This repository contains the refactored Docker Compose configuration with a modular and standardized approach.

## NEW: Unified Docker Setup

A new unified Docker Compose configuration has been implemented that consolidates all services into a single file with consistent health checks and dependencies. To use this new setup:

```bash
# Make the script executable
chmod +x restart-all-containers.sh

# Start all services
./restart-all-containers.sh
```

For detailed information about the unified Docker setup, see:
- [DOCKER_SETUP.md](./DOCKER_SETUP.md) - Quick overview of Docker options
- [docker-compose.unified.yml](./docker-compose.unified.yml) - The unified Docker Compose configuration file
- [AGENT_SERVICE_INTEGRATION.md](./AGENT_SERVICE_INTEGRATION.md) - Guide for integrating agent services

## Features

- **Unified Docker Compose Configuration**: All services defined in a standard way
- **Environment-Specific Configurations**: Development and production settings
- **Component-Based Organization**: Services grouped by logical components
- **Standardized Service Naming**: Consistent naming convention
- **Unified Management Script**: Single `alfred.sh` script for all operations

## Directory Structure

```
alfred-agent-platform-v2/
├── services/                   # Service implementations
│   ├── alfred-bot/             # Alfred bot service
│   ├── alfred-core/            # Core agent service
│   ├── social-intel/           # Social intelligence agent
│   ├── financial-tax/          # Financial tax agent
│   ├── legal-compliance/       # Legal compliance agent
│   ├── rag-service/            # Retrieval augmented generation
│   └── ...
├── monitoring/                 # Monitoring configuration
│   ├── grafana/                # Grafana dashboards
│   └── prometheus/             # Prometheus configuration
├── tests/                      # Test scripts
├── migrations/                 # Database migrations
├── docker-compose.unified.yml  # NEW: Unified configuration (recommended)
├── docker-compose.yml          # Base configuration
├── docker-compose.dev.yml      # Development overrides
├── docker-compose.prod.yml     # Production overrides
├── docker-compose.core.yml     # Core component configuration
├── docker-compose.agents.yml   # Agent component configuration
├── docker-compose.ui.yml       # UI component configuration
├── docker-compose.monitoring.yml # Monitoring component configuration
├── restart-all-containers.sh   # NEW: Unified management script (recommended)
├── .env.example                # Example environment variables
├── alfred.sh                   # Legacy management script
├── DOCKER_SETUP.md             # Docker setup documentation
└── README.md                   # This file
```

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Bash shell

### Installation

```bash
# Clone the repository
git clone https://github.com/[your-organization]/alfred-agent-platform-v2.git
cd alfred-agent-platform-v2

# Copy example environment file
cp .env.example .env

# Option 1: Use the recommended unified setup
chmod +x restart-all-containers.sh
./restart-all-containers.sh

# Option 2: Or use the legacy setup with components
./alfred.sh start --env=dev --components=core
```

### Managing Services

#### Using the Unified Setup (Recommended)

```bash
# Start all services
./restart-all-containers.sh

# Check container status
docker ps

# View logs for a specific service
docker logs <container-name>

# Restart a specific service
docker restart <container-name>

# Stop and remove all containers
docker stop $(docker ps -q) && docker rm $(docker ps -aq)
```

#### Using the Legacy Setup

```bash
# Start all services in development mode
./alfred.sh start --env=dev

# Start only agent components in production mode
./alfred.sh start --env=prod --components=agents

# View logs for a specific service
./alfred.sh logs --service=alfred-bot

# Stop all services
./alfred.sh stop

# Clean up resources
./alfred.sh clean
```

## Platform Structure

Alfred Agent Platform v2 is organized into several components:

### Core Infrastructure
- Redis (in-memory data store)
- Vector Database (Qdrant)
- PubSub Emulator (message queue)
- Local LLM Service (optional)

### Database Services
- PostgreSQL Database
- Authentication Service
- REST API
- Admin UI
- Realtime Updates
- File Storage

### Agent Services
- Core Agent Service (orchestration)
- RAG Service (knowledge retrieval)
- Atlas Agent (architecture agent)
- Domain-specific agents (social, financial, legal)

### UI Services
- Chat UI (Streamlit-based)
- Admin Dashboard

### Monitoring Services
- Prometheus (metrics collection)
- Grafana (dashboards)
- System and Database Exporters

## Components

The platform is organized into the following components:

- **Core**: Infrastructure services (Redis, PostgreSQL, PubSub)
- **Agents**: AI agent services
- **UI**: User interface services
- **Monitoring**: Observability services

## Development

For development, you can use the `--env=dev` option (default), which:

- Enables hot reloading for services
- Mounts code volumes for live editing
- Sets up debugging tools
- Uses development-friendly defaults

Example development workflow:

```bash
# Start core services
./alfred.sh start --components=core

# Start agent services for development
./alfred.sh start --components=agents

# View logs from a specific service
./alfred.sh logs --service=agent-core --follow
```

## Production Deployment

For production, use the `--env=prod` option, which:

- Uses pre-built images
- Sets resource constraints
- Configures production-appropriate logging
- Enables proper restart policies

Example production deployment:

```bash
# Build all images
./alfred.sh build

# Start all services in production mode
./alfred.sh start --env=prod
```

## Testing

```bash
# Run all tests
cd tests
./run-all-tests.sh

# Run specific test
./test-service-health.sh
```

## Documentation

- [Service Implementation Guide](SERVICE_IMPLEMENTATION_GUIDE.md) - How to implement services
- [Migration Guide](MIGRATION_GUIDE.md) - How to migrate from earlier versions
- [Validation Report](VALIDATION.md) - Test results and validation
- [Progress Report](PROGRESS.md) - Current status of the refactoring project

## Troubleshooting

If you encounter issues, check the logs:

```bash
# View logs from all services
./alfred.sh logs

# View logs from a specific service
./alfred.sh logs --service=agent-core
```

For more advanced troubleshooting:

```bash
# Check service status
./alfred.sh status

# Execute commands in containers
./alfred.sh exec --service=redis redis-cli ping

# Restart services
./alfred.sh restart
```

If problems persist, try cleaning up and starting fresh:

```bash
./alfred.sh clean --force
./alfred.sh start
```

## License

[MIT License](LICENSE)
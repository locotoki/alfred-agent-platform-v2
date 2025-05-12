# Alfred Agent Platform v2

This repository contains the Alfred Agent Platform v2, a comprehensive platform for building and managing AI agents.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/your-org/alfred-agent-platform-v2.git
cd alfred-agent-platform-v2

# Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# Start the platform (all components, development mode)
./alfred.sh start

# Start only core components
./alfred.sh start --components=core

# Start the platform in production mode
./alfred.sh start --env=prod
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

## Configuration

The platform uses Docker Compose for configuration, with a modular structure:

- `docker-compose.yml`: Base configuration with all services
- `docker-compose.dev.yml`: Development-specific settings
- `docker-compose.prod.yml`: Production-specific settings
- `docker-compose.core.yml`: Core infrastructure and database services
- `docker-compose.agents.yml`: Agent services
- `docker-compose.ui.yml`: UI services
- `docker-compose.monitoring.yml`: Monitoring services

Environment variables are stored in `.env` (see `.env.example` for available options).

## Management Script

The `alfred.sh` script provides a unified interface for managing the platform:

```bash
# Start all services in development mode
./alfred.sh start

# Start specific components
./alfred.sh start --components=core,agents

# Start in production mode
./alfred.sh start --env=prod

# View logs
./alfred.sh logs --service=agent-core

# Execute command in container
./alfred.sh exec --service=redis redis-cli info

# Stop all services
./alfred.sh stop

# Clean up resources
./alfred.sh clean --force
```

For a complete list of commands and options:

```bash
./alfred.sh help
```

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

## Monitoring

The platform includes comprehensive monitoring:

- Prometheus for metrics collection
- Grafana for dashboards
- Node Exporter for system metrics
- Postgres Exporter for database metrics

Access Grafana at http://localhost:3005 (login: admin/admin or as configured).

## Testing

The platform includes a comprehensive test suite to validate the configuration and functionality.

### Running Tests

To run all tests:

```bash
cd tests
./run-all-tests.sh
```

To run individual tests:

```bash
# Test Docker Compose files
./tests/validate-compose.sh

# Test alfred.sh script
./tests/test-alfred-script.sh

# Test service health checks
./tests/test-service-health.sh

# Test core services
./tests/test-core-services.sh
```

### Installation

An installation script is provided to help with migrating to the new configuration:

```bash
# Show what would be changed without making any changes
./install.sh --test

# Install and backup existing files
./install.sh --backup

# Force installation without confirmation
./install.sh --force
```

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

[License information]
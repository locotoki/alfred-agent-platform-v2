# Alfred Agent Platform v2 - Quick Start Guide

This guide provides streamlined instructions for running the Alfred Agent Platform v2 with all its components.

## Prerequisites

- Docker and Docker Compose installed
- Make utility installed
- Bash shell environment

## NEW: Unified Docker Compose Setup (Recommended)

The recommended way to start the platform is using the new unified Docker Compose setup:

```bash
# Make the script executable
chmod +x restart-all-containers.sh

# Start all services
./restart-all-containers.sh
```

This unified setup provides:
- Consistent health checks for all services
- Proper dependency management
- Simplified startup procedure
- Clear organization of services

For more details, examine the configuration file at [docker-compose.unified.yml](./docker-compose.unified.yml) and the documentation in [DOCKER_SETUP.md](./DOCKER_SETUP.md).

## Alternative: Start with Legacy Scripts

If you prefer the original setup, you can use the provided script:

```bash
# Start all services
./start-clean.sh

# Start with specific components only
./start-clean.sh --core --rag --agents

# See all options
./start-clean.sh --help
```

## Using the Makefile

You can also use the Makefile directly:

```bash
# Start all services
make start-all

# Start specific service groups
make up-core       # Core infrastructure (Redis, Qdrant, Supabase, etc.)
make up-atlas      # Atlas services (RAG Gateway, Worker)
make up-agents     # Agent services (Alfred Bot, Social Intel, etc.)
make up-ui         # UI services (Mission Control)
make up-monitoring # Monitoring services (Prometheus, Grafana)

# View logs
make logs          # All services
make logs-f        # Follow logs for all services
make logs-service SVC=atlas  # Specific service
make logs-f-service SVC=atlas  # Follow logs for specific service

# Other useful commands
make ps            # List running containers
make stop          # Stop all services
make clean         # Stop and remove all containers, networks, and volumes
```

## Configuration Scripts

Several configuration scripts are available to help manage the environment:

```bash
# Set up the Supabase database schema
./setup-supabase-fixed.sh

# Disable authentication for development
./disable-auth.sh

# Fix JWT token configuration
./fix-jwt-config.sh

# Fix Atlas health endpoint
./apply-health-fix.sh

# Verify platform functionality
./verify-platform.sh
```

## Access Points

Once started, you can access the following services:

### With Unified Setup

- **Chat UI (ui-chat)**: http://localhost:8502
- **Admin Dashboard (ui-admin)**: http://localhost:3007
- **Auth UI (auth-ui)**: http://localhost:3006
- **Monitoring Dashboard (Grafana)**: http://localhost:3005 (login: admin/admin)
- **Prometheus Metrics**: http://localhost:9090
- **Mail Interface (MailHog)**: http://localhost:8025
- **LLM API (Ollama)**: http://localhost:11434
- **Supabase Studio (db-admin)**: http://localhost:3001
- **Vector DB (Qdrant)**: http://localhost:6333/dashboard
- **PostgreSQL REST API**: http://localhost:3000

### With Legacy Setup

- **Mission Control UI**: http://localhost:3007
- **RAG Gateway (agent-rag)**: http://localhost:8501
- **Atlas API (agent-atlas)**: http://localhost:8000
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3005 (login: admin/admin)
- **Alfred Bot (agent-core)**: http://localhost:8011
- **Social Intelligence Agent**: http://localhost:9000
- **Financial Tax Agent**: http://localhost:9003
- **Legal Compliance Agent**: http://localhost:9002
- **Supabase Studio**: http://localhost:3001

## Supabase Database Access

With authentication disabled for development, you can access Supabase directly:

```bash
# Read from a table
curl http://localhost:3000/architect_in

# Write to a table
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"data":{"message":"test"}}' \
  http://localhost:3000/architect_in
```

## Troubleshooting

### With Unified Setup

If you encounter issues with the unified setup:

1. Check container status: `docker ps -a`
2. View container logs: `docker logs <container-name>`
3. Restart a specific container: `docker restart <container-name>`
4. Clean up and restart all containers: `./restart-all-containers.sh`
5. Check individual container health: `docker inspect <container-name> | grep -A 10 "Health"`

### With Legacy Setup

If you encounter issues with the legacy setup:

1. Check container status: `docker ps -a`
2. View container logs: `make logs-service SVC=service-name`
3. Restart specific service: `docker-compose -f docker-compose.combined-fixed.yml restart service-name`
4. Clean up and restart: `make clean && make start-all`
5. Run `./disable-auth.sh` if Supabase authentication is causing problems

## Architecture Overview

The Alfred Agent Platform v2 consists of several components:

1. **Core Infrastructure**:
   - Redis (`redis`) - In-memory data store
   - Vector-DB (`vector-db`) - Qdrant for embeddings storage
   - PubSub Emulator (`pubsub-emulator`) - Message queue for service communication
   - LLM Service (`llm-service`) - Ollama for local LLM inference

2. **LLM Infrastructure**:
   - Model Registry (`model-registry`) - Manages available LLM models
   - Model Router (`model-router`) - Routes LLM requests to appropriate backend

3. **Database Services (Supabase)**:
   - DB Postgres (`db-postgres`) - PostgreSQL database
   - DB Auth (`db-auth`) - Database authentication service
   - DB API (`db-api`) - Database REST API
   - DB Admin (`db-admin`) - Database admin UI
   - DB Realtime (`db-realtime`) - Database realtime updates
   - DB Storage (`db-storage`) - Database storage

4. **Agent Services**:
   - Agent Core (`agent-core`) - Core agent service
   - Agent RAG (`agent-rag`) - RAG service
   - Agent Atlas (`agent-atlas`) - Atlas agent
   - Agent Social (`agent-social`) - Social intelligence agent
   - Agent Financial (`agent-financial`) - Financial tax agent
   - Agent Legal (`agent-legal`) - Legal compliance agent

5. **UI Services**:
   - UI Chat (`ui-chat`) - Chat UI
   - UI Admin (`ui-admin`) - Admin dashboard
   - Auth UI (`auth-ui`) - Authentication UI

6. **Monitoring Services**:
   - Monitoring Metrics (`monitoring-metrics`) - Prometheus metrics collection
   - Monitoring Dashboard (`monitoring-dashboard`) - Grafana dashboard
   - Monitoring Node (`monitoring-node`) - Host metrics exporter
   - Monitoring DB (`monitoring-db`) - Database metrics exporter
   - Monitoring Redis (`monitoring-redis`) - Redis metrics exporter

7. **Mail Services**:
   - Mail Server (`mail-server`) - MailHog for local email testing

## Docker Compose Structure

The platform uses a streamlined Docker Compose structure:

### Unified Setup (Recommended)
- `docker-compose.unified.yml`: New unified configuration with all services in one file
- `restart-all-containers.sh`: Helper script for managing the unified setup
- `DOCKER_SETUP.md`: Documentation for the Docker setup options

### Legacy Setup
- `docker-compose.yml`: Original base services file
- `docker-compose.dev.yml`: Development configuration overrides
- `docker-compose.prod.yml`: Production configuration overrides
- `docker-compose.core.yml`: Core infrastructure services
- `docker-compose.agents.yml`: Agent services configuration
- `docker-compose.ui.yml`: UI services configuration
- `docker-compose.monitoring.yml`: Monitoring services configuration
- `docker-compose.combined-fixed.yml`: Comprehensive configuration with all services in one file

For simplicity with the legacy setup, we use the combined configuration for all operations through the Makefile and startup script. However, the new unified setup is recommended for most users.

## Database Schema

The platform uses several key tables in Supabase:

1. **architect_in**: Input queue for Atlas (messages sent to Atlas for processing)
2. **architect_out**: Output from Atlas processing (results from Atlas)
3. **agent-specific tables**: Each agent has dedicated tables for its data
   - alfred_bot_tasks: Tasks for the Alfred Bot
   - social_intel_analysis: Analysis data for Social Intelligence agent
   - financial_tax_records: Records for Financial Tax agent
   - legal_compliance_checks: Compliance data for Legal agent

## Health Monitoring

All services implement standardized health endpoints:

```bash
# Check Atlas basic health status
curl http://localhost:8000/healthz

# Check Atlas detailed health information
curl http://localhost:8000/health

# Check RAG Gateway health
curl http://localhost:8501/healthz

# Check Prometheus health
curl http://localhost:9090/-/healthy
```

You can also use the verification script for a comprehensive check:

```bash
./verify-platform.sh
```

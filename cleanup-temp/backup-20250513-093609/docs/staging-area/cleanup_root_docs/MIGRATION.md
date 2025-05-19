# Alfred Agent Platform v2 - Migration Guide

This document provides guidance for migrating from the old Docker Compose configuration to the new unified structure.

## Overview

The new configuration offers several improvements:

- **Unified Structure**: A single base configuration with modular overrides
- **Standardized Naming**: Consistent naming conventions for services
- **Better Documentation**: Clear documentation and examples
- **Simplified Management**: A unified script for managing the platform
- **Improved Development Experience**: Better environment-specific settings

## Migration Steps

### 1. Backup Your Current Configuration

Before making any changes, back up your current configuration:

```bash
# Create a backup directory
mkdir -p ~/alfred-backups/$(date +%Y%m%d)

# Copy current Docker Compose files
cp docker-compose*.yml ~/alfred-backups/$(date +%Y%m%d)/

# Backup environment files
cp .env* ~/alfred-backups/$(date +%Y%m%d)/
```

### 2. Install the New Configuration

Use the installation script to install the new configuration:

```bash
# Test installation (doesn't make any changes)
./refactor-unified/install.sh --test

# Install with backup
./refactor-unified/install.sh --backup
```

### 3. Migrate Environment Variables

Create a new `.env` file based on the `.env.example`:

```bash
# Copy the example
cp .env.example .env

# Edit the file
# Note: Many environment variables have been renamed with a prefix (ALFRED_, DB_, etc.)
```

#### Environment Variable Mapping

Here's a mapping of important environment variables from the old to the new configuration:

| Old Name | New Name | Description |
|----------|----------|-------------|
| POSTGRES_PASSWORD | DB_PASSWORD | Database password |
| JWT_SECRET | DB_JWT_SECRET | JWT secret for auth |
| OPENAI_API_KEY | ALFRED_OPENAI_API_KEY | OpenAI API key |
| SLACK_BOT_TOKEN | ALFRED_SLACK_BOT_TOKEN | Slack bot token |
| SLACK_SIGNING_SECRET | ALFRED_SLACK_SIGNING_SECRET | Slack signing secret |
| ENVIRONMENT | ALFRED_ENVIRONMENT | Environment (development, production) |
| DEBUG | ALFRED_DEBUG | Debug mode |
| DATABASE_URL | ALFRED_DATABASE_URL | Database connection URL |
| GCP_PROJECT_ID | ALFRED_PROJECT_ID | GCP project ID |
| YOUTUBE_API_KEY | ALFRED_YOUTUBE_API_KEY | YouTube API key |

### 4. Understand Service Name Changes

Service names have been standardized to improve consistency. Here's a mapping of important services:

| Old Name | New Name | Description |
|----------|----------|-------------|
| redis | redis | Redis (unchanged) |
| qdrant | vector-db | Vector database |
| supabase-db | db-postgres | PostgreSQL database |
| supabase-auth | db-auth | Authentication service |
| supabase-rest | db-api | REST API for database |
| alfred-bot, alfred | agent-core | Core agent service |
| rag-gateway | agent-rag | RAG service |
| atlas | agent-atlas | Atlas agent |
| streamlit-chat | ui-chat | Chat UI |
| mission-control | ui-admin | Admin dashboard |
| prometheus | monitoring-metrics | Metrics collection |
| grafana | monitoring-dashboard | Monitoring dashboards |

Volumes have also been renamed to match service names:

| Old Name | New Name | Description |
|----------|----------|-------------|
| supabase-db-data | db-postgres-data | PostgreSQL data |
| qdrant-storage | vector-db-data | Vector database data |
| redis-data | redis-data | Redis data (unchanged) |
| grafana-data | monitoring-dashboard-data | Grafana data |
| ollama-models | llm-service-data | LLM models |

### 5. Start with Core Services

Start with just the core services to test basic functionality:

```bash
./alfred.sh start --components=core --clean
```

Verify that the core services are running:

```bash
./alfred.sh status
```

Check that basic services are functioning:

```bash
# Test Redis
./alfred.sh exec --service=redis redis-cli ping

# Test PostgreSQL
./alfred.sh exec --service=db-postgres pg_isready -U postgres

# Check logs
./alfred.sh logs --service=db-postgres
```

### 6. Gradually Add More Services

Once the core services are working, gradually add more services:

```bash
# Add agent services
./alfred.sh start --components=agents

# Add UI services
./alfred.sh start --components=ui

# Add monitoring services
./alfred.sh start --components=monitoring
```

### 7. Test the Full Stack

Finally, test the complete stack:

```bash
./alfred.sh start
```

## Common Issues and Solutions

### Volume Data Migration

If you need to migrate data from old volumes to new ones:

```bash
# Stop all services
./alfred.sh stop --force

# List volumes
docker volume ls

# Copy data from old to new volume
docker run --rm -v supabase-db-data:/old -v db-postgres-data:/new -w / alpine cp -av /old/. /new/
```

### Environment Variable Conflicts

If you encounter issues with environment variables:

- Check for conflicts between old and new variable names
- Ensure all required variables are set in `.env`
- Check service logs for environment-related errors

### Service Discovery Issues

If services can't find each other:

- Verify service names in environment variables (e.g., `ALFRED_API_URL=http://agent-core:8011`)
- Check that all services are on the same network
- Inspect the Docker network: `docker network inspect alfred-network`

## Command Mapping

Here's a mapping of common commands from the old to the new configuration:

| Old Command | New Command | Description |
|-------------|-------------|-------------|
| docker-compose up -d | ./alfred.sh start | Start all services |
| docker-compose -f docker-compose.combined-fixed.yml up -d | ./alfred.sh start | Start all services |
| ./start-clean.sh --core | ./alfred.sh start --components=core --clean | Start core services |
| ./start-clean.sh --all | ./alfred.sh start --clean | Start all services |
| docker-compose -f docker-compose.monitoring.yml up -d | ./alfred.sh start --components=monitoring | Start monitoring services |
| docker-compose logs | ./alfred.sh logs | View all logs |
| docker-compose logs redis | ./alfred.sh logs --service=redis | View specific service logs |
| docker-compose restart | ./alfred.sh restart | Restart services |
| docker-compose down | ./alfred.sh stop --force | Stop all services |
| docker-compose exec redis redis-cli | ./alfred.sh exec --service=redis redis-cli | Execute command in container |

## Rollback Procedure

If you need to revert to the old configuration:

```bash
# Stop all services
./alfred.sh stop --force

# Restore from backup
cp ~/alfred-backups/YYYYMMDD/docker-compose*.yml .
cp ~/alfred-backups/YYYYMMDD/.env* .

# Start with old configuration
docker-compose up -d
# or
./start-clean.sh --all
```

## Getting Help

If you encounter issues during migration:

1. Check the logs: `./alfred.sh logs`
2. Run the tests: `./tests/run-all-tests.sh`
3. Check the documentation: `README.md`
4. Restore from backup if needed

## Training Resources

- Read the new `README.md` for comprehensive documentation
- Explore the `tests` directory for examples of how to use the new configuration
- Try different combinations of components to understand the modular structure
- Refer to this migration guide for mapping between old and new concepts

# Alfred Agent Platform v2 - Unified Docker Compose Design

## Design Philosophy

1. **Single Source of Truth**: One base docker-compose.yml with all services
2. **Modularity**: Logical grouping of services
3. **Override-Based Configuration**: Use docker-compose's override mechanism
4. **Environment Variables**: Proper use of environment variables with sensible defaults
5. **Consistency**: Standard naming and configuration
6. **Documentation**: Comprehensive documentation

## File Structure

```
docker-compose.yml                  # Base configuration with all services
docker-compose.override.yml         # Local development settings (gitignored)
docker-compose.dev.yml              # Development environment settings
docker-compose.prod.yml             # Production environment settings
docker-compose.core.yml             # Core services only (infrastructure + data)
docker-compose.agents.yml           # Agent services only
docker-compose.ui.yml               # UI services only
docker-compose.monitoring.yml       # Monitoring services only
.env.example                        # Example environment variables
.env                                # Local environment variables (gitignored)
```

## Base Configuration (docker-compose.yml)

This file will:
- Define all services with their minimal, essential configuration
- Group services logically with comments
- Use consistent naming across all services
- Set sensible defaults for environment variables
- Define all volumes and networks
- Include health checks for all services

## Environment-Specific Overrides

### Development (docker-compose.dev.yml)
- Bind mounts for code
- Debug settings
- Hot reloading
- Non-production credentials

### Production (docker-compose.prod.yml)
- Resource constraints
- Restart policies
- Production-appropriate logging
- No bind mounts

## Component-Specific Overrides

### Core (docker-compose.core.yml)
- Infrastructure services (Redis, Qdrant, PubSub)
- Data services (Supabase components)

### Agents (docker-compose.agents.yml)
- Alfred/Alfred-Bot
- Atlas
- RAG Gateway
- Domain-specific agents

### UI (docker-compose.ui.yml)
- Streamlit Chat
- Mission Control

### Monitoring (docker-compose.monitoring.yml)
- Prometheus
- Grafana
- Exporters

## Startup Script (alfred.sh)

A comprehensive script that:
- Creates/manages the Docker network
- Handles environment selection (--env=dev|prod)
- Supports component selection (--components=core,agents,ui,monitoring)
- Provides operations (start, stop, restart, logs, etc.)
- Includes helpful documentation

Example usage:
```
./alfred.sh start --env=dev --components=core,agents,ui
./alfred.sh stop
./alfred.sh logs alfred
./alfred.sh status
```

## Service Naming Conventions

All services will follow a consistent naming pattern:

| Type | Pattern | Example |
|------|---------|---------|
| Infrastructure | service-name | redis, qdrant |
| Supabase | supabase-component | supabase-db, supabase-auth |
| Agents | agent-name | alfred, atlas |
| UI | ui-name | streamlit-chat, mission-control |
| Monitoring | monitoring-name | prometheus, grafana |

## Environment Variable Standards

Environment variables will be organized by purpose:
- `ALFRED_` prefix for platform-wide settings
- Service-specific prefixes for service settings (e.g., `SUPABASE_`, `RAG_`)
- Clear documentation in .env.example

## Health Checks

All services will include appropriate health checks to ensure proper startup order and monitoring.

## Networking

All services will use a single `alfred-network` by default.

## Volumes

All persistent data will use named volumes with clear, consistent naming.

## Implementation Plan

1. Create base docker-compose.yml with all services
2. Create environment-specific override files
3. Create component-specific override files
4. Create unified startup script
5. Test all combinations
6. Document usage patterns
7. Migrate existing configurations
8. Deprecate old files
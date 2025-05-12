# Alfred Agent Platform v2 - Service Naming Convention

To ensure consistency across all configurations, we will adopt the following standard naming convention for all services.

## General Rules

1. Use `kebab-case` for all service names (lowercase with hyphens)
2. Group names should come first (e.g., `supabase-`, `agent-`, etc.)
3. Avoid abbreviations unless universally understood
4. Be consistent with the same concept across different services

## Service Categories and Naming Patterns

### Core Infrastructure Services

| Current Name(s) | New Standardized Name | Description |
|-----------------|------------------------|-------------|
| redis | redis | Redis in-memory data store |
| qdrant | vector-db | Vector database for embeddings |
| pubsub-emulator | pubsub-emulator | GCP PubSub emulator |
| ollama | llm-service | Local large language model service |

### Data Services (Supabase)

| Current Name(s) | New Standardized Name | Description |
|-----------------|------------------------|-------------|
| supabase-db | db-postgres | Main PostgreSQL database |
| supabase-auth | db-auth | Authentication service |
| supabase-rest | db-api | REST API for database access |
| supabase-studio | db-admin | Admin UI for database |
| supabase-realtime | db-realtime | Real-time database updates |
| supabase-storage | db-storage | File storage service |

### Agent Services

| Current Name(s) | New Standardized Name | Description |
|-----------------|------------------------|-------------|
| alfred, alfred-bot | agent-core | Core agent orchestration service |
| atlas | agent-atlas | Architecture agent |
| rag-gateway | agent-rag | Retrieval augmented generation service |
| social-intel | agent-social | Social intelligence agent |
| financial-tax | agent-financial | Financial domain agent |
| legal-compliance | agent-legal | Legal domain agent |

### UI Services

| Current Name(s) | New Standardized Name | Description |
|-----------------|------------------------|-------------|
| streamlit-chat | ui-chat | Chat interface |
| mission-control | ui-admin | Administration dashboard |

### Monitoring Services

| Current Name(s) | New Standardized Name | Description |
|-----------------|------------------------|-------------|
| prometheus | monitoring-metrics | Metrics collection |
| grafana | monitoring-dashboard | Monitoring dashboards |
| node-exporter | monitoring-node | Host system metrics exporter |
| postgres-exporter | monitoring-db | Database metrics exporter |

## Volume Naming

Volumes will follow the pattern `<service>-data`:

| Current Name | New Standardized Name |
|--------------|------------------------|
| supabase-db-data | db-postgres-data |
| qdrant-storage | vector-db-data |
| redis-data | redis-data |
| grafana-data | monitoring-dashboard-data |
| ollama-models | llm-service-data |

## Network Naming

The single network will be:

| Current Name | New Standardized Name |
|--------------|------------------------|
| alfred-network | alfred-network (unchanged) |

## Environment Variable Prefixes

Environment variables will use these standard prefixes:

| Service Category | Prefix |
|------------------|--------|
| Platform-wide | ALFRED_ |
| Database | DB_ |
| Agent-specific | AGENT_ |
| UI-specific | UI_ |
| Monitoring | MONITORING_ |
| LLM-specific | LLM_ |

## Transition Strategy

When implementing the new naming convention:

1. Document old-to-new name mappings
2. Update all service references
3. Update all volumes
4. Update all environment variable references
5. Test thoroughly to ensure no references are missed

This naming convention will be applied to all new Docker Compose files, while maintaining backward compatibility during the transition period.
# Alfred Agent Platform v2 - Service Inventory

## Core Infrastructure Services

| Service | Description | Ports | Dependencies | Notes |
|---------|-------------|-------|-------------|-------|
| redis | In-memory data store | 6379 | None | Used for caching, queues, etc. |
| qdrant | Vector database | 6333, 6334 | None | Stores embeddings for RAG |
| pubsub-emulator | GCP PubSub emulator | 8085 | None | Message queue for service communication |
| ollama | Local LLM service | 11434 | None | Optional GPU integration |

## Data Services (Supabase)

| Service | Description | Ports | Dependencies | Notes |
|---------|-------------|-------|-------------|-------|
| supabase-db | PostgreSQL database | 5432 | None | Core database |
| supabase-auth | Authentication service | 9999 | supabase-db | User auth management |
| supabase-rest | REST API for database | 3000 | supabase-db | PostgREST interface |
| supabase-studio | Admin UI | 3001 | supabase-db, supabase-rest | Stub in combined config |
| supabase-realtime | Real-time updates | 4000 | supabase-db | Stub in combined config |
| supabase-storage | File storage | 5000 | supabase-db, supabase-rest | Stub in combined config |

## Agent Services

| Service | Description | Ports | Dependencies | Notes |
|---------|-------------|-------|-------------|-------|
| alfred / alfred-bot | Core orchestration service | 8011 | redis, pubsub-emulator, supabase-db | Named differently in different configs |
| atlas | Architecture agent | 8000 | rag-gateway, redis, pubsub-emulator | AI agent for architecture tasks |
| rag-gateway | Retrieval service | 8501 | qdrant | Handles knowledge retrieval |
| social-intel | Social intelligence agent | 9000 | supabase-db, pubsub-emulator, redis | Stub in some configs |
| financial-tax | Financial agent | 9003 | supabase-db, pubsub-emulator, redis | Stub in some configs |
| legal-compliance | Legal agent | 9002 | supabase-db, pubsub-emulator, redis | Stub in some configs |

## UI Services

| Service | Description | Ports | Dependencies | Notes |
|---------|-------------|-------|-------------|-------|
| streamlit-chat | Chat UI | 8501 | alfred / alfred-bot | User interface for chat |
| mission-control | Admin dashboard | 3007 | Various | Stub in some configs |

## Monitoring Services

| Service | Description | Ports | Dependencies | Notes |
|---------|-------------|-------|-------------|-------|
| prometheus | Metrics collection | 9090 | None | Time-series database |
| grafana | Monitoring dashboards | 3005 | prometheus | Visualization UI |
| node-exporter | System metrics | 9100 | None | Exports host metrics |
| postgres-exporter | Database metrics | 9187 | supabase-db | Exports database metrics |

## Service Naming Inconsistencies

1. `alfred` (in main docker-compose) vs `alfred-bot` (in combined-fixed)
2. Slightly different configurations for most services across files

## Environment Variables

Many services rely on environment variables for configuration:

- Database credentials
- API keys (e.g., OPENAI_API_KEY)
- Service URLs (e.g., REDIS_URL, RAG_URL)
- Feature flags (e.g., AUTH_ENABLED, DEBUG)

## Dependencies Graph

Core dependencies:
- Most agents depend on: redis, pubsub-emulator, supabase-db
- UI services depend on agent services
- Monitoring services depend on their respective targets

## Volume Usage

| Volume | Used By | Purpose |
|--------|---------|---------|
| supabase-db-data | supabase-db | Database persistence |
| supabase-storage-data | supabase-storage | File storage persistence |
| qdrant-storage | qdrant | Vector database persistence |
| ollama-models | ollama | LLM model storage |
| redis-data | redis | Redis persistence |
| prometheus-data | prometheus | Metrics persistence |
| grafana-data | grafana | Dashboard configuration persistence |
| social-intel-data | social-intel | Agent data persistence |
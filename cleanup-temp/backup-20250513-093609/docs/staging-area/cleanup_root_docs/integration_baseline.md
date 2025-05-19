# Alfred Agent Platform Integration Baseline

## 1. Docker-Compose Services

| Service Name | Image | Exposed Ports | File Path |
|--------------|-------|---------------|-----------|
| redis | redis:7-alpine | 6379 | docker-compose.yml |
| vector-db | qdrant/qdrant:v1.7.4 | 6333, 6334 | docker-compose.yml |
| pubsub-emulator | gcr.io/google.com/cloudsdktool/cloud-sdk:latest | 8085 | docker-compose.yml |
| llm-service | ollama/ollama:latest | 11434 | docker-compose.yml |
| db-postgres | supabase/postgres:15.1.0.117 | 5432 | docker-compose.yml |
| db-auth | supabase/gotrue:v2.132.3 | 9999 | docker-compose.yml |
| db-api | postgrest/postgrest:v11.2.0 | 3000 | docker-compose.yml |
| db-admin | alpine:latest | 3001 | docker-compose.yml |
| db-realtime | alpine:latest | 4000 | docker-compose.yml |
| db-storage | alpine:latest | 5000 | docker-compose.yml |
| agent-core | agent-core:latest | 8011 | docker-compose.yml |
| agent-rag | rag-gateway:latest | 8501 | docker-compose.yml |
| agent-atlas | worker:latest | 8000 | docker-compose.yml |
| agent-social | alpine:latest | 9000 | docker-compose.yml |
| agent-financial | alpine:latest | 9003 | docker-compose.yml |
| agent-legal | alpine:latest | 9002 | docker-compose.yml |
| ui-chat | ui-chat:latest | 8501 | docker-compose.yml |
| ui-admin | alpine:latest | 3007 | docker-compose.yml |
| monitoring-metrics | prom/prometheus:v2.48.1 | 9090 | docker-compose.yml, docker-compose.monitoring.yml |
| monitoring-dashboard | grafana/grafana:10.2.3 | 3005 | docker-compose.yml, docker-compose.monitoring.yml |
| monitoring-node | prom/node-exporter:v1.7.0 | 9100 | docker-compose.yml, docker-compose.monitoring.yml |
| monitoring-db | prometheuscommunity/postgres-exporter:v0.15.0 | 9187 | docker-compose.yml, docker-compose.monitoring.yml |

## 2. Pub/Sub Topics

Based on the files examined, the following PubSub topics are currently used or referenced:

| Topic | Description | Referenced In |
|-------|-------------|---------------|
| agent_tasks | Main task queue for agent processing | services/atlas/app.py, services/agent-core |
| agent_results | Results from agent task processing | services/atlas/app.py, services/agent-core |
| atlas_tasks | Tasks specifically for Atlas agent | services/atlas/app.py |
| atlas_results | Results from Atlas processing | services/atlas/app.py |
| notification_events | System notifications and events | services/agent-core |

## 3. Environment Variables

| Variable | Description | Referenced In |
|----------|-------------|---------------|
| ALFRED_ENVIRONMENT | Environment (development, production) | docker-compose.yml, docker-compose.dev.yml |
| ALFRED_DEBUG | Debug mode flag | docker-compose.yml, docker-compose.dev.yml |
| ALFRED_MODE | Operation mode | docker-compose.yml |
| ALFRED_ENABLE_SLACK | Slack integration flag | docker-compose.yml |
| ALFRED_DATABASE_URL | Database connection string | docker-compose.yml |
| ALFRED_REDIS_URL | Redis connection URL | docker-compose.yml |
| ALFRED_PUBSUB_EMULATOR_HOST | PubSub emulator host/port | docker-compose.yml |
| ALFRED_PROJECT_ID | GCP project ID | docker-compose.yml |
| ALFRED_SLACK_BOT_TOKEN | Slack bot token | docker-compose.yml |
| ALFRED_SLACK_SIGNING_SECRET | Slack signing secret | docker-compose.yml |
| ALFRED_OPENAI_API_KEY | OpenAI API key | docker-compose.yml |
| ALFRED_QDRANT_URL | Qdrant vector DB URL | docker-compose.yml |
| ALFRED_DEFAULT_COLLECTION | Default vector collection | docker-compose.yml |
| ALFRED_ENABLE_COLLECTIONS | Collections feature flag | docker-compose.yml |
| ALFRED_AUTH_ENABLED | Authentication flag | docker-compose.yml |
| ALFRED_API_KEYS | API keys for services | docker-compose.yml |
| ALFRED_RATE_LIMIT_REQUESTS | Rate limit request count | docker-compose.yml |
| ALFRED_RATE_LIMIT_WINDOW_SECONDS | Rate limit window period | docker-compose.yml |
| ALFRED_LOG_LEVEL | Logging level | docker-compose.yml, docker-compose.dev.yml |
| ALFRED_LOG_AGENT_ACCESS | Log agent access flag | docker-compose.yml |
| ALFRED_SUPABASE_URL | Supabase URL | docker-compose.yml |
| ALFRED_SUPABASE_KEY | Supabase API key | docker-compose.yml |
| ALFRED_GOOGLE_APPLICATION_CREDENTIALS | GCP credentials path | docker-compose.yml |
| ALFRED_YOUTUBE_API_KEY | YouTube API key | docker-compose.yml |
| ALFRED_RAG_URL | RAG gateway URL | docker-compose.yml |
| ALFRED_RAG_API_KEY | RAG gateway API key | docker-compose.yml |
| ALFRED_RAG_COLLECTION | RAG collection name | docker-compose.yml |
| ALFRED_API_URL | Alfred API URL | docker-compose.yml |
| DB_USER | Database username | docker-compose.yml |
| DB_PASSWORD | Database password | docker-compose.yml |
| DB_NAME | Database name | docker-compose.yml |
| DB_JWT_SECRET | JWT secret for database | docker-compose.yml |
| DB_JWT_EXP | JWT expiration time | docker-compose.yml |
| MONITORING_ADMIN_PASSWORD | Monitoring admin password | docker-compose.yml, docker-compose.monitoring.yml |
| GF_SECURITY_ADMIN_PASSWORD | Grafana admin password | docker-compose.monitoring.yml |
| GF_USERS_ALLOW_SIGN_UP | Grafana signup allowance | docker-compose.dev.yml |
| GF_AUTH_ANONYMOUS_ENABLED | Grafana anonymous access | docker-compose.dev.yml |
| GF_INSTALL_PLUGINS | Grafana plugins to install | docker-compose.dev.yml |
| GF_LOG_LEVEL | Grafana log level | docker-compose.dev.yml |

## 4. CI Jobs

A complete CI/CD workflow analysis would require examining the GitHub workflows directory, but based on the Makefile, these build targets exist:

| Target | Description | Referenced In |
|--------|-------------|---------------|
| build | Build all services | Makefile |
| atlas-dev | Start Atlas development stack | Makefile |
| atlas-monitor | Start Atlas with monitoring | Makefile |

## 5. Prometheus Metrics Endpoints

| Service | Metrics Endpoint | Referenced In |
|---------|------------------|---------------|
| agent-core | /metrics | docker-compose.yml (implied by Prometheus configuration) |
| agent-rag | /metrics | docker-compose.yml (implied by Prometheus configuration) |
| agent-atlas | /metrics | docker-compose.yml (implied by Prometheus configuration) |
| db-postgres | Exported via monitoring-db on port 9187 | docker-compose.yml, docker-compose.monitoring.yml |
| redis | Implied metrics endpoint | docker-compose.monitoring.yml (likely scraped by Prometheus) |
| node | /metrics on port 9100 | docker-compose.monitoring.yml |

## 6. Available Ports

Based on the services already defined, these ports are currently occupied:

| Port Range | Services |
|------------|----------|
| 3000-3007 | db-api (3000), db-admin (3001), monitoring-dashboard (3005), ui-admin (3007) |
| 4000 | db-realtime |
| 5000 | db-storage |
| 6333-6379 | vector-db (6333, 6334), redis (6379) |
| 8000-8501 | agent-atlas (8000), agent-core (8011), agent-rag (8501), ui-chat (8501) |
| 9000-9003 | agent-social (9000), agent-legal (9002), agent-financial (9003) |
| 9090-9999 | monitoring-metrics (9090), monitoring-node (9100), monitoring-db (9187), db-auth (9999) |
| 11434 | llm-service |

## 7. Available Ports for New Services

Based on the port allocations above, these are some available port ranges that could be used for the new CrewAI and n8n services:

| Service | Suggested Port Range |
|---------|---------------------|
| CrewAI Service | 9004-9010 |
| n8n Service | 5500-5600 |

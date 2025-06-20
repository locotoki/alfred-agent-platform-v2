# GA v3.0.0 Container Analysis

## Containers Built in GA v3.0.0 Release

Based on the docker-release.yml workflow, these images were built and pushed:

| Service | GA Image | Current Status |
|---------|----------|----------------|
| alfred-core | ghcr.io/digital-native-ventures/alfred-agent-platform-v2/alfred-core:v3.0.0 | ❌ Using v0.9.6 |
| alfred-bot | ghcr.io/digital-native-ventures/alfred-agent-platform-v2/alfred-bot:v3.0.0 | ❌ Not running |
| agent-bizops | ghcr.io/digital-native-ventures/alfred-agent-platform-v2/agent-bizops:v3.0.0 | ❌ Using edge tag |
| contact-ingest | ghcr.io/digital-native-ventures/alfred-agent-platform-v2/contact-ingest:v3.0.0 | ❌ Using latest |
| crm-sync | ghcr.io/digital-native-ventures/alfred-agent-platform-v2/crm-sync:v3.0.0 | ✅ Using test v3.0.1 |
| slack-app | ghcr.io/digital-native-ventures/alfred-agent-platform-v2/slack-app:v3.0.0 | ❌ Not found |
| architect-api | ghcr.io/digital-native-ventures/alfred-agent-platform-v2/architect-api:v3.0.0 | ❌ Using local build |
| db-metrics | ghcr.io/digital-native-ventures/alfred-agent-platform-v2/db-metrics:v3.0.0 | ❌ Using latest |
| slack-adapter | ghcr.io/digital-native-ventures/alfred-agent-platform-v2/slack-adapter:v3.0.0 | ❌ Using local build |
| mission-control | ghcr.io/digital-native-ventures/alfred-agent-platform-v2/mission-control:v3.0.0 | ❌ Not running |
| pubsub | ghcr.io/digital-native-ventures/alfred-agent-platform-v2/pubsub:v3.0.0 | ❌ Not found |
| rag-gateway | ghcr.io/digital-native-ventures/alfred-agent-platform-v2/rag-gateway:v3.0.0 | ❌ Using atlas-rag-gateway |

## Containers NOT in GA v3.0.0 Release

These services are running but were NOT included in the GA release workflow:

### Local/Test Images
- agent-atlas (atlas-worker:latest)
- agent-rag (atlas-rag-gateway:latest)
- auth-ui (auth-ui:latest)
- model-registry (model-registry:latest)
- model-router (model-router:latest)
- pubsub-metrics (pubsub-metrics:latest)
- slack_mcp_gateway (slack-mcp-gateway:latest)
- ui-admin (mission-control-simplified:latest)
- ui-chat (ui-chat-test:v3.0.0)

### Third-Party Images
- db-admin (supabase/studio:20231123-64a766a)
- db-api (postgrest/postgrest:v11.2.0)
- db-auth (supabase/gotrue:v2.132.3)
- db-postgres (postgres:15-alpine-hardened)
- db-realtime (supabase/realtime:v2.25.35)
- db-storage (postgres:15.5-alpine)
- hubspot-mock (ghcr.io/locotoki/hubspot-mock:latest)
- llm-service (ollama/ollama:latest)
- mail-server (mailhog/mailhog:latest)
- monitoring-dashboard (grafana/grafana:10.2.3)
- monitoring-db (prometheuscommunity/postgres-exporter:v0.15.0)
- monitoring-metrics (prom/prometheus:v2.48.1)
- monitoring-node (prom/node-exporter:v1.7.0)
- monitoring-redis (oliver006/redis_exporter:v1.55.0)
- pubsub-emulator (gcr.io/google.com/cloudsdktool/cloud-sdk:latest)
- redis (redis:7-alpine)
- redis-exporter (docker.io/oliver006/redis_exporter:v1.62.0)
- telegram-adapter (ghcr.io/alfred/alfred-platform/telegram-adapter:latest)
- vector-db (qdrant/qdrant:v1.7.4)

## Summary

- **Total running containers**: 41
- **GA v3.0.0 images available**: 12
- **Actually using GA images**: 1 (crm-sync with v3.0.1 patch)
- **Missing from GA release**: 10+ custom services

## Key Issues

1. Most containers are NOT using the GA v3.0.0 images
2. Several important services were not included in the GA release:
   - ui-chat
   - ui-admin
   - model-registry
   - model-router
   - slack_mcp_gateway
   - Various metrics services

3. The deployment is using a mix of:
   - Old versions (agent-core:v0.9.6)
   - Latest/edge tags (not GA versions)
   - Local builds
   - Third-party images

## Recommendation

To properly test GA v3.0.0, the docker-compose.override.yml should be updated to use ALL the GA v3.0.0 images that were built. Currently, only crm-sync has been overridden.
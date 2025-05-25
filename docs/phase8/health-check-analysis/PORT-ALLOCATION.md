# Port Allocation Strategy

**Last Updated**: May 25, 2025
**Status**: All port conflicts resolved ✅

## Recent Changes
- `slack_mcp_gateway`: 3000 → 3010 (resolved conflict with db-api)
- `slack-adapter`: 3001 → 3011 (resolved conflict with db-admin)
- `hubspot-mock`: 8000 → 8088 (resolved conflict with agent-atlas)

## Core Services (3000-3099)
- 3000: db-api ✅
- 3001: db-admin ✅
- 3002: ui-admin
- 3005: monitoring-dashboard (Grafana) ✅
- 3006: auth-ui
- 3010: slack_mcp_gateway ✅ (moved from 3000)
- 3011: slack-adapter ✅ (moved from 3001)

## Agent Services (8000-8099)
- 8000: agent-atlas ✅
- 8011: agent-core ✅
- 8012: agent-bizdev
- 8020: agent-rag
- 8088: hubspot-mock ✅ (moved from 8000)
- 9000: agent-social ✅

## Database Services (5400-5499)
- 5432: db-postgres (PostgreSQL)
- 5433: db-realtime (if needed)

## Cache & Queue Services (6300-6399)
- 6333: vector-db (Qdrant)
- 6334: vector-db (gRPC)
- 6379: redis

## Monitoring Services (9000-9199)
- 9090: monitoring-metrics (Prometheus)
- 9091-9129: Various metrics exporters
- 9187: redis-exporter

## Other Services
- 11434: llm-service (Ollama)
- 1025: mail-server (SMTP)
- 8025: mail-server (Web UI)
- 8085: pubsub-emulator
- 4000: db-realtime

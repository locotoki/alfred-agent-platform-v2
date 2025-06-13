# Alfred Agent Platform v2 - Cross-Platform Consistency

## Service Architecture (Profile-Based)

### Core Infrastructure (--profile dev)
- db-postgres (PostgreSQL)
- redis 
- vector-db (Qdrant)
- db-api (PostgREST)
- mail-server (MailHog)

### LLM Services (--profile llm)  
- llm-service (Ollama)
- model-router
- model-registry

### Agent Services (--profile agents)
- agent-core ← Main orchestrator
- agent-rag 
- agent-social
- pubsub-emulator

### UI Services (--profile ui) ← THE MISSING PIECE\!
- ui-chat → http://localhost:8502 ← This was missing\!
- ui-admin → http://localhost:3007

### Authentication (--profile auth)
- db-auth (GoTrue)
- auth-ui

### Monitoring (--profile monitoring)  
- monitoring-metrics (Prometheus)
- monitoring-dashboard (Grafana)

## CONSISTENT DEPLOYMENT COMMANDS

### Minimal Development
```bash
docker compose --profile dev --profile llm up -d
```

### Full Development (Matches Windows)
```bash  
docker compose --profile dev --profile llm --profile ui up -d
```

### Production Stack
```bash
docker compose --profile llm --profile agents --profile ui --profile auth up -d
```

## ENDPOINT CONSISTENCY

Same URLs work on macOS, Windows, Linux:

### UI Layer (Previously Missing on macOS)
- Chat UI: http://localhost:8502
- Admin UI: http://localhost:3007  
- Auth UI: http://localhost:3006

### Core APIs
- Agent Core: http://localhost:8011/health
- PostgreSQL: localhost:5432
- Redis: localhost:6379
- Qdrant: http://localhost:6333/collections

### Monitoring  
- Grafana: http://localhost:3005
- Prometheus: http://localhost:9090

## THE SOLUTION

To ensure platform consistency, ALWAYS use profiles:

```bash
# This gives you the SAME services on any platform
docker compose --profile dev --profile llm --profile ui up -d
```

The missing chat-UI was simply due to the --profile ui flag not being used\!

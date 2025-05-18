# Local Development Quick Start

## Overview
One-command setup for the complete Alfred Agent Platform local development environment.

## Prerequisites
- Docker Engine 25.0+
- Docker Compose v2
- Python 3.11+
- 4GB+ RAM available

## Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/locotoki/alfred-agent-platform-v2.git
cd alfred-agent-platform-v2
make init
```

### 2. Configure Environment
```bash
cp .env.example .env
# Edit .env with your API keys and tokens
```

### 3. Start Everything
```bash
# Start all 34 services with one command
make up

# Stop everything
make down
```

## What Gets Started

### Infrastructure (6 services)
- Redis (caching, pub/sub)
- PubSub (message broker)
- PubSub Metrics (monitoring)
- Database Storage (Supabase)
- Vector Database (Qdrant)
- n8n (workflow automation)

### Databases (7 services)
- PostgreSQL (main database)
- DB Metrics (monitoring)
- Supabase REST API
- Supabase Realtime
- Supabase Auth
- Supabase Storage
- Supabase Image Proxy

### LLM Services (4 services)
- Model Registry
- Model Router
- OpenLLM
- CrewAI

### Core Services (8 services)
- Alfred Core
- Agent Orchestrator
- Agent RAG
- Financial Tax Agent
- Legal Compliance Agent
- Social Intelligence Agent
- Slack App
- Slack MCP Gateway

### UI Services (4 services)
- Mission Control
- Mission Control Simplified
- Streamlit Chat
- Auth UI

### Monitoring (2 services)
- Prometheus
- Grafana

### Other (3 services)
- API Gateway
- WhatsApp Adapter

## Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| Mission Control | http://localhost:3007 | N/A |
| Streamlit Chat | http://localhost:8502 | N/A |
| Grafana | http://localhost:3005 | admin/admin |
| Prometheus | http://localhost:9090 | N/A |
| Supabase Studio | http://localhost:3001 | From .env |
| Financial API | http://localhost:9003/docs | N/A |
| Social Intel API | http://localhost:9000/docs | N/A |

## Compose Generation

The platform uses a modular compose system:

```bash
# Regenerate docker-compose.generated.yml from service snippets
make compose-generate

# View all available make targets
make help
```

## Troubleshooting

### Out of Memory
Reduce services by using profiles:
```bash
# Start only core services
docker compose -f docker-compose.generated.yml --profile core up -d

# Start core + monitoring
docker compose -f docker-compose.generated.yml --profile core --profile monitoring up -d
```

### Port Conflicts
Check for conflicting services:
```bash
docker ps
netstat -tlnp | grep :3000
```

### Service Health
Check service status:
```bash
docker compose -f docker-compose.generated.yml ps
docker compose -f docker-compose.generated.yml logs [service-name]
```

## Next Steps

1. **Configure agents**: Update agent-specific environment variables
2. **Set up monitoring**: Access Grafana at http://localhost:3005
3. **Test integrations**: Use the Slack app or chat UI
4. **Develop features**: Services hot-reload in development mode

For detailed deployment guides, see:
- [Deployment Documentation](docs/deployment/)
- [Service Documentation](docs/services/)
- [Agent Development Guide](docs/agents/)

> **Tip :** If `pre-commit` throws a read-only DB error, run:
> `export PRE_COMMIT_HOME=$HOME/.cache/pre-commit`

# Container Assessment - 27 Running Services

## Core Infrastructure (5) ✅ ESSENTIAL
1. **redis** - Message broker/cache
2. **db-postgres** - Main database  
3. **pubsub-emulator** - Google PubSub for async messaging
4. **vector-db** - Qdrant vector database for RAG
5. **pubsub-metrics** - Metrics for pubsub

## Agents (5) 🤔 EVALUATE
6. **agent-core** ✅ - Main agent orchestrator
7. **agent-atlas** - Worker agent (unhealthy)
8. **agent-bizdev** - Business development agent (unhealthy)
9. **agent-rag** - RAG gateway (unhealthy)
10. **agent-social** - Social intelligence (unhealthy)

## LLM/Model Services (3) 🤔 EVALUATE
11. **llm-service** - Ollama for local LLMs (unhealthy)
12. **model-registry** - Model management (unhealthy)
13. **model-router** - Routes to different models (unhealthy)

## Database/Supabase (3) 🤔 ALREADY REDUCED
14. **db-auth** - Supabase authentication
15. **db-api** - REST API (PostgREST)
16. **db-exporter** - PostgreSQL metrics

## Monitoring (4) ✅ ALREADY REDUCED
17. **monitoring-metrics** - Prometheus
18. **monitoring-dashboard** - Grafana
19. **monitoring-node** - System metrics (unhealthy)
20. **redis-exporter** - Redis metrics (unhealthy)

## UI Services (2) ❌ QUESTIONABLE
21. **auth-ui** - Authentication UI (unhealthy)
22. **ui-admin** - Mission control UI (unhealthy)

## Communication (2) ✅ ESSENTIAL
23. **slack-bot** - Slack integration v3.1.0
24. **telegram-adapter** - Telegram integration

## Mock/Test Services (2) ❌ REMOVE
25. **hubspot-mock** - Mock CRM service (unhealthy)
26. **mail-server** - MailHog test email server (unhealthy)

## Unknown (1) ❓
27. **db-metrics** - Custom metrics service

## Immediate Removal Candidates

### Test/Mock Services (Not for Production)
- **hubspot-mock** - Mock service, not needed
- **mail-server** - MailHog is for testing only

### Broken UI Services
- **auth-ui** - Unhealthy, likely not used
- **ui-admin** - Mission control broken

### Questionable Agents
- **agent-atlas** - Unhealthy
- **agent-bizdev** - Unhealthy  
- **agent-social** - Unhealthy

### LLM Services (if not using local models)
- **llm-service** - Ollama (if using OpenAI/Anthropic)
- **model-registry** - If not managing multiple models
- **model-router** - If using single provider

## Potential Reduction
- **Current**: 27 containers
- **Remove mocks/test**: 25 containers (-2)
- **Remove broken UIs**: 23 containers (-2)
- **Remove unhealthy agents**: 20 containers (-3)
- **Remove unused LLM stack**: 17 containers (-3)
- **Potential minimum**: ~17 containers
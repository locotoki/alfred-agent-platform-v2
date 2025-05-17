# Health Check Implementation - Infrastructure Services Plan

## Current Status

✅ **ALL CORE SERVICES IMPLEMENTED**: We have successfully implemented standardized health checks for all 8 essential services:
1. Model Registry
2. Model Router
3. Agent Core
4. Financial Tax Agent
5. Legal Compliance Agent 
6. RAG Service
7. UI Chat
8. UI Admin

## Next Services to Implement

Now that all core services have standardized health checks, we can extend the implementation to infrastructure services. Here's the priority list for the next phase:

### Priority 1: Agent Services
1. **Agent-Atlas** - Atlas agent service
   - Implementation approach: Direct FastAPI implementation
   - Port mapping: 9101

2. **Agent-Social** - Social intelligence agent
   - Implementation approach: Direct FastAPI implementation
   - Port mapping: 9102

### Priority 2: Core Infrastructure
3. **Redis** - In-memory data store
   - Implementation approach: Wrapper service with healthcheck binary
   - Port mapping: 9103

4. **Vector-DB (Qdrant)** - Vector database for embeddings
   - Implementation approach: Direct implementation of HTTP health check
   - Port mapping: 9104

5. **PubSub-Emulator** - Message queue
   - Implementation approach: Wrapper service with healthcheck binary
   - Port mapping: 9105

6. **LLM-Service (Ollama)** - Local LLM service
   - Implementation approach: Wrapper service with healthcheck binary
   - Port mapping: 9106

### Priority 3: Database Services
7. **DB-Postgres** - PostgreSQL database
   - Implementation approach: Wrapper service with healthcheck binary
   - Port mapping: 9107

8. **DB-Auth** - Database authentication service
   - Implementation approach: Direct implementation or wrapper
   - Port mapping: 9108

9. **DB-API** - Database REST API
   - Implementation approach: Direct implementation or wrapper
   - Port mapping: 9109

10. **DB-Admin** - Database admin UI
    - Implementation approach: Direct implementation or wrapper
    - Port mapping: 9110

11. **DB-Realtime** - Database realtime updates
    - Implementation approach: Direct implementation or wrapper
    - Port mapping: 9111

12. **DB-Storage** - Database storage service
    - Implementation approach: Direct implementation or wrapper
    - Port mapping: 9112

### Priority 4: Auxiliary Services
13. **Auth-UI** - Authentication UI
    - Implementation approach: Direct implementation in Express
    - Port mapping: 9113

14. **Mail-Server** - Mail server
    - Implementation approach: Wrapper service with healthcheck binary
    - Port mapping: 9114

15. **Monitoring services** (monitoring-dashboard, monitoring-metrics, monitoring-node, monitoring-db, monitoring-redis)
    - Implementation approach: Direct implementation or wrapper
    - Port mapping: 9115-9120

## Implementation Approach

For each service, follow these steps:

1. **Assessment**:
   - Determine if the service already has health check capabilities
   - Identify the best approach (direct implementation or wrapper)
   - Check dependencies and connectivity requirements

2. **Implementation**:
   - Follow the guide in HEALTH_CHECK_INTEGRATION_GUIDE.md
   - Use appropriate implementation method based on service type
   - Maintain consistent port mapping scheme

3. **Validation**:
   - Test health and metrics endpoints
   - Verify Prometheus scraping
   - Update dashboard configuration

4. **Documentation**:
   - Update documentation with implementation details
   - Add service-specific notes if needed

## Port Mapping Convention Extension

To maintain consistency, we'll continue the port mapping scheme:

| Service | Container Port | Host Port |
|---------|----------------|-----------|
| agent-core | 9091 | 9091 |
| alfred-bot | 9091 | 9095 |
| model-registry | 9091 | 9093 |
| model-router | 9091 | 9094 |
| agent-financial | 9091 | 9096 |
| agent-legal | 9091 | 9097 |
| ui-chat | 9091 | 9098 |
| agent-rag | 9091 | 9099 |
| ui-admin | 9091 | 9100 |
| agent-atlas | 9091 | 9101 |
| agent-social | 9091 | 9102 |
| redis | 9091 | 9103 |
| vector-db | 9091 | 9104 |
| pubsub-emulator | 9091 | 9105 |
| llm-service | 9091 | 9106 |
| db-postgres | 9091 | 9107 |
| ... and so on |

## Next Steps

1. **Validate Current Implementation**:
   - Start all core services with `docker-compose up -d`
   - Run the validation script: `./scripts/healthcheck/validate-all-healthchecks.sh`
   - Fix any issues with the current implementation

2. **Prioritize Infrastructure Services**:
   - Begin with agent-atlas and agent-social
   - Continue with core infrastructure services
   - Finally implement database and auxiliary services

3. **Create Infrastructure-specific Templates**:
   - Develop templates for wrapper services
   - Create standard patterns for common service types
   - Document best practices for each service category

4. **Enhance Monitoring**:
   - Expand Grafana dashboard to include infrastructure services
   - Create service dependency visualization
   - Add alerting rules for critical services
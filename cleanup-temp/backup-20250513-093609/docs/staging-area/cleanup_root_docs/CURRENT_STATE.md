# Alfred Agent Platform v2 - Current State

This document provides a summary of the current state of the Alfred Agent Platform v2 environment.

## System Overview

The platform consists of 21 services organized in several groups:

1. **Core Infrastructure**
   - Redis: Caching service
   - Qdrant: Vector database
   - PubSub Emulator: Message queue emulator

2. **Supabase Services**
   - Supabase DB: PostgreSQL database
   - Supabase REST: REST API for database access
   - Supabase Auth: Authentication service
   - Supabase Realtime: Real-time updates (stub)
   - Supabase Storage: File storage (stub)
   - Supabase Studio: Admin UI (stub)

3. **Atlas Services**
   - RAG Gateway: Vector search and RAG functionality (port 8501)
   - Atlas: Main worker service for processing AI tasks (port 8000)

4. **Agent Services**
   - Alfred Bot: Main assistant agent with Slack integration
   - Social Intel: Social media intelligence agent (stub with RAG + Supabase connection)
   - Financial Tax: Financial and tax intelligence agent (stub with RAG + Supabase connection)
   - Legal Compliance: Legal and compliance intelligence agent (stub with RAG + Supabase connection)

5. **Mission Control**
   - Mission Control: Admin dashboard (stub)

6. **Monitoring**
   - Prometheus: Metrics collection
   - Grafana: Metrics visualization and dashboards
   - Node Exporter: System metrics exporter
   - Postgres Exporter: Database metrics exporter

7. **Utility Services**
   - Ollama: Local LLM hosting

## Configuration Changes

The following changes have been made to streamline the environment:

1. **Docker Compose Configuration**
   - Created `docker-compose.combined-fixed.yml` with all services defined properly
   - Fixed image names and service dependencies
   - Standardized network configuration

2. **Environment Variables**
   - Updated JWT secrets to use the same token across services
   - Fixed Supabase URLs to point to correct internal services

3. **Service Naming**
   - Renamed `atlas-rag-gateway` to `rag-gateway`
   - Renamed `atlas-worker` to `atlas`

4. **Health Endpoints**
   - Created and implemented patches for health endpoints on Atlas and RAG Gateway services
   - Patched metrics.py in Atlas to properly return 200 OK for /healthz endpoint
   - Added detailed /health endpoint to provide service status information
   - Documented implementation in `/patches` directory

5. **Supabase Authentication**
   - Created scripts to fix authentication issues between services and Supabase
   - Disabled RLS for development purposes to ensure all services can access data
   - Set up database schema with required tables for agent services

6. **Slack Integration**
   - Implemented Slack bot interface using the Slack Bolt SDK
   - Added support for slash commands, direct messages, and mentions
   - Created ngrok configuration for local development
   - Implemented rich message formatting using Slack's Block Kit
   - Added real-time event handling for interactive conversations

## Startup Options

You can start the environment in several ways:

1. **Using the clean startup script**
   ```bash
   ./start-clean.sh              # Start all services
   ./start-clean.sh --core --rag # Start only core and RAG services
   ```

2. **Using the Makefile**
   ```bash
   make start-all                # Start all services
   make up-core                  # Start core services
   make up-atlas                 # Start Atlas services
   ```

## Database Setup

Supabase has been configured with the following tables:

1. **architect_in**: Input data queue for Atlas
2. **architect_out**: Output data from Atlas processing
3. **service_role_test**: Test table for service role access
4. **agent-specific tables**:
   - alfred_bot_tasks
   - social_intel_analysis
   - financial_tax_records
   - legal_compliance_checks

## Authentication Configuration

Authentication has been simplified for development:

1. **Development Mode**: Authentication is currently disabled for ease of development
2. **Direct API Access**: Services can access Supabase REST API without authentication headers
3. **Row Level Security**: RLS is disabled for all tables to simplify development
4. **Documentation**: See `SUPABASE_STATUS.md` for details on the current authentication setup

## Environment Variables

Key environment variables have been set in the `.env` file:

- JWT_SECRET: JWT token for authentication
- SERVICE_ROLE_KEY: Service role key for Supabase
- SUPABASE_URL: Internal URL for Supabase REST API

## API Key Configuration

RAG Gateway is configured with API keys for each agent:

- Atlas: `atlas-key`
- Alfred Bot: `alfred-key`
- Social Intelligence: `social-key`
- Financial Tax: `financial-key`
- Legal Compliance: `legal-key`

Each agent service is configured with:

- SUPABASE_URL: The URL of the Supabase REST API
- SUPABASE_SERVICE_ROLE_KEY: The JWT token for authentication
- RAG_URL: The URL of the RAG Gateway
- RAG_API_KEY: The API key specific to that agent
- RAG_COLLECTION: The vector collection to query

## Known Issues

1. **Stub Services**
   - Several services are currently implemented as stubs (Alpine containers)
   - These would need to be replaced with actual implementations as development progresses

## Next Steps

1. Test and refine the Slack bot with a real Slack workspace
2. Implement proper authentication for production environment
3. Replace remaining stub services with actual implementations
4. Add more comprehensive monitoring with Prometheus and Grafana
5. Enhance the Slack bot with more advanced natural language understanding

## Additional Resources

- See `QUICKSTART.md` for quick reference commands
- Check `patches/README.md` for implementation details of health endpoint patches
- See `SUPABASE_STATUS.md` for details on the current Supabase configuration

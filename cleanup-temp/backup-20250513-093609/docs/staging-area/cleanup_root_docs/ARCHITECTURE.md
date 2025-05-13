# Alfred Agent Platform v2 - Architecture

This document describes the overall architecture and interaction patterns of the Alfred Agent Platform v2.

## System Overview

The Alfred Agent Platform is designed around a microservices architecture with:
- Event-driven communication
- Stateless services
- Persistent storage
- Vector search capabilities
- AI processing
- Comprehensive monitoring

## Core Components

### Container Structure

![Container Architecture](./docs/images/container-architecture.png)

The platform consists of 21 services organized in several functional groups:

1. **Core Infrastructure**
   - **Supabase DB**: PostgreSQL database with pgvector extension
   - **Supabase REST**: REST API for database access
   - **Supabase Auth**: Authentication service
   - **Redis**: In-memory cache and message broker
   - **Qdrant**: Vector database for embeddings
   - **PubSub Emulator**: Messaging system for event-driven architecture

2. **Atlas Services**
   - **RAG Gateway**: Vector search and retrieval service
   - **Atlas**: Core processing service for AI tasks

3. **Agent Services**
   - **Alfred Bot**: Assistant agent for Slack interaction
   - **Social Intel**: Social media intelligence agent
   - **Financial Tax**: Financial analysis and tax agent
   - **Legal Compliance**: Legal and compliance checking agent

4. **Monitoring Services**
   - **Prometheus**: Metrics collection
   - **Grafana**: Visualization and dashboards
   - **Node Exporter**: System metrics collection
   - **Postgres Exporter**: Database metrics collection

### Data Flow Architecture

The platform uses an event-driven architecture with message passing:

1. **Ingestion Flow**:
   - External requests come into agent services
   - Agents enqueue tasks to Atlas via Supabase tables
   - Atlas processes the tasks with AI models
   - Results are stored in output tables
   - Agents retrieve results for delivery

2. **RAG Flow**:
   - Atlas queries RAG Gateway for relevant context
   - RAG Gateway performs vector search in Qdrant
   - Context is returned to Atlas for AI processing

3. **Monitoring Flow**:
   - Services export metrics
   - Prometheus scrapes metrics
   - Grafana visualizes metrics and alerts

## Networking Architecture

The platform uses a dedicated Docker network (`alfred-network`) for service-to-service communication:

- Services communicate using internal DNS names (e.g., `rag-gateway`, `supabase-rest`)
- External access is provided through port mapping
- Authentication is handled by JWT tokens and API keys

## Data Storage

### Database Structure

The platform uses several database tables for different purposes:

1. **Atlas Message Bus**:
   - `architect_in`: Input queue for Atlas
   - `architect_out`: Output from Atlas processing

2. **Agent-Specific Storage**:
   - `alfred_bot_tasks`: Tasks for Alfred Bot
   - `social_intel_analysis`: Analysis data
   - `financial_tax_records`: Financial data
   - `legal_compliance_checks`: Compliance data

### Vector Storage

The platform uses Qdrant for storing and retrieving vector embeddings:

- **Collections**: Organized by domain (e.g., `general-knowledge`, `financial`, `legal`)
- **Search**: Uses cosine similarity for semantic similarity
- **Metadata**: Includes source, timestamp, and context information

## Authentication and Security

The platform uses a multi-layered authentication approach:

1. **Service-to-Service Auth**:
   - JWT tokens for Supabase authentication
   - API keys for RAG Gateway access

2. **User Authentication**:
   - JWT-based authentication through Supabase Auth
   - Role-based access control

3. **Row Level Security**:
   - Database-level security policies
   - Enables multi-tenancy and data isolation

## Health Monitoring

All services implement standardized health endpoints:

- `/healthz`: Basic health check for liveness probes
- `/health`: Detailed health status with dependencies

Monitoring uses a combination of:
- Prometheus metrics
- Service health checks
- Container healthchecks

## Development and Deployment

### Local Development Flow

For local development, the platform uses:
- Docker Compose for container orchestration
- Volume mounts for code changes
- Authentication disabled for easier debugging

### Production Deployment (Future)

Production deployment will use:
- Kubernetes for orchestration
- Proper secrets management
- Full authentication and RBAC
- High availability configuration

## Integration Points

### External API Integration

The platform provides several integration points:

1. **REST API**:
   - `/api/v1/chat`: Chat API for agent interaction
   - `/api/v1/search`: Vector search API

2. **Message Bus**:
   - Supabase Realtime for event notifications
   - PubSub topics for event distribution

3. **Webhooks**:
   - Slack integration
   - GitHub integration
   - Custom webhook endpoints

## Scaling Considerations

The platform is designed for horizontal scaling:

1. **Atlas Workers**:
   - Can be scaled horizontally
   - Process tasks from shared queue

2. **RAG Gateway**:
   - Stateless with DB-stored configuration
   - Can be scaled horizontally

3. **Qdrant**:
   - Supports clustering for large vector collections
   - Can scale to billions of vectors
# Alfred Agent Platform v2 - Service Catalog

> Last Updated: May 10, 2025

This document provides a comprehensive catalog of all services in the Alfred Agent Platform v2, including their current status, documentation, and migration information.

## Table of Contents

- [Overview](#overview)
- [Agent Services](#agent-services)
- [Infrastructure Services](#infrastructure-services)
- [UI Services](#ui-services)
- [Messaging Services](#messaging-services)
- [Observability Services](#observability-services)
- [Service Dependencies](#service-dependencies)
- [Documentation Migration Status](#documentation-migration-status)

## Overview

The Alfred Agent Platform v2 consists of multiple interconnected services that work together to provide a comprehensive agent orchestration and execution platform. Services are containerized using Docker and orchestrated with Docker Compose for consistent deployment across environments.

## Agent Services

| Service | Description | Port | Status | Documentation Status | Migration Status | Priority |
|---------|-------------|------|--------|---------------------|-----------------|----------|
| **Alfred Bot** | Main interface bot with Slack integration | 8011 | ✅ Active | Comprehensive | Complete | Low |
| **Social Intelligence** | Performs social media analysis and trend detection | 9000 | ✅ Active | Comprehensive | Complete | Low |
| **Legal Compliance** | Handles legal and regulatory compliance checks | 9002 | ✅ Active | Comprehensive | Complete | Low |
| **Financial-Tax** | Provides financial analysis and tax compliance verification | 9003 | ✅ Active | Partial | In Progress | High |

### Alfred Bot Service

**Description:** The core agent that serves as the primary interface for users through Slack integration. Handles initial request processing and delegates tasks to specialized agents.

**Endpoints:**
- `/health/health` - Service health check
- `/api/v1/slack/events` - Slack event webhook
- `/api/v1/slack/commands` - Slack command endpoint

**Documentation:**
- `/docs/architecture/system-design.md` - System architecture
- `/docs/api/a2a-protocol.md` - A2A protocol documentation

**Dependencies:**
- Supabase Auth (Authentication)
- Pub/Sub Emulator (Messaging)
- Redis (Caching)

### Social Intelligence Agent

**Description:** Specialized agent for social media analysis, trend detection, sentiment analysis and market research.

**Endpoints:**
- `/health/health` - Service health check
- `/api/v1/trend-analysis` - Trend analysis endpoint
- `/api/v1/sentiment-analysis` - Sentiment analysis endpoint
- `/api/v1/social-monitor` - Social media monitoring endpoint

**Documentation:**
- `/docs/agents/social-intelligence-agent.md` - Agent documentation
- `/docs/workflows/niche-scout-implementation-guide.md` - Niche scout workflow

**Dependencies:**
- Qdrant (Vector database)
- Pub/Sub Emulator (Messaging)
- Supabase DB (State storage)

### Legal Compliance Agent

**Description:** Specialized agent for checking legal and regulatory compliance across multiple jurisdictions.

**Endpoints:**
- `/health/health` - Service health check
- `/api/v1/compliance-check` - Compliance check endpoint
- `/api/v1/regulation-scan` - Regulation scan endpoint
- `/api/v1/policy-update-check` - Policy update check endpoint
- `/api/v1/legal-risk-assessment` - Legal risk assessment endpoint

**Documentation:**
- `/docs/agents/legal-compliance-agent.md` - Agent documentation

**Dependencies:**
- Pub/Sub Emulator (Messaging)
- Supabase DB (State storage)
- Redis (Caching)

### Financial-Tax Agent

**Description:** Specialized agent for financial analysis and tax compliance verification.

**Endpoints:**
- `/health/health` - Service health check
- `/api/v1/financial-analysis` - Financial analysis endpoint
- `/api/v1/tax-compliance` - Tax compliance check endpoint

**Documentation:**
- `/docs/agents/financial-tax-agent.md` - Agent documentation
- `/docs/agents/financial-tax-deployment-checklist.md` - Deployment checklist

**Dependencies:**
- Pub/Sub Emulator (Messaging)
- Supabase DB (State storage)
- Qdrant (Vector database)

## Infrastructure Services

| Service | Description | Port | Status | Documentation Status | Migration Status | Priority |
|---------|-------------|------|--------|---------------------|-----------------|----------|
| **Supabase DB** | PostgreSQL database with pgvector extension | 5432 | ✅ Active | Comprehensive | Complete | Low |
| **Supabase Auth** | Authentication service | 9999 | ✅ Active | Partial | Complete | Low |
| **Supabase REST** | REST API for database access | 3000 | ✅ Active | Partial | Complete | Medium |
| **Supabase Realtime** | WebSocket connections for real-time updates | 4000 | ✅ Active | Partial | Complete | Medium |
| **Supabase Storage** | File management and storage | 5000 | ✅ Active | Partial | Complete | Medium |
| **Redis** | In-memory caching service | 6379 | ✅ Active | Minimal | Complete | Medium |
| **Qdrant** | Vector database for embeddings and search | 6333 | ✅ Active | Partial | Complete | Medium |
| **Ollama** | Local LLM deployment | N/A | ✅ Active | Minimal | Complete | Low |

### Supabase Stack

**Description:** Comprehensive database and authentication stack providing PostgreSQL with vector support, auth, REST API, and file storage.

**Endpoints:**
- Supabase DB: PostgreSQL connection on port 5432
- Supabase Auth: `/health` - Health check on port 9999
- Supabase REST: `/` - API root on port 3000
- Supabase Realtime: `/` - WebSocket endpoint on port 4000
- Supabase Storage: `/health` - Health check on port 5000

**Documentation:**
- `/docs/architecture/system-design.md` - Database architecture

**Dependencies:**
- None (core infrastructure service)

### Redis

**Description:** In-memory caching service used for transient data storage and caching.

**Endpoints:**
- Redis connection on port 6379

**Documentation:**
- Limited documentation available

**Dependencies:**
- None (core infrastructure service)

### Qdrant

**Description:** Vector database for storing and querying vector embeddings, enabling efficient semantic searches.

**Endpoints:**
- `/health` - Health check on port 6333
- REST API on port 6333
- GRPC on port 6334

**Documentation:**
- `/docs/architecture/system-design.md` - Vector database section

**Dependencies:**
- None (core infrastructure service)

### Ollama

**Description:** Local LLM deployment service for in-house AI model hosting.

**Endpoints:**
- Internal API endpoint

**Documentation:**
- Limited documentation available

**Dependencies:**
- None (core infrastructure service)

## UI Services

| Service | Description | Port | Status | Documentation Status | Migration Status | Priority |
|---------|-------------|------|--------|---------------------|-----------------|----------|
| **Mission Control** | Main dashboard for platform monitoring and control | 3007 | ✅ Active | Partial | In Progress | High |
| **Supabase Studio** | Web interface for database management | 3001 | ✅ Active | Minimal | Complete | Low |
| **Grafana** | Dashboard visualization for metrics | 3002 | ✅ Active | Minimal | Complete | Medium |

### Mission Control

**Description:** Primary user interface for platform monitoring, agent management, and workflow control.

**Endpoints:**
- `/api/health` - Health check on port 3007
- `/api/agents` - Agent status endpoint
- `/api/tasks` - Task management endpoint
- `/api/metrics` - Metrics endpoint

**Documentation:**
- `/docs/phase6-mission-control/requirements.md` - Requirements
- `/docs/phase6-mission-control/implementation-plan.md` - Implementation plan

**Dependencies:**
- Supabase REST (Database access)
- Supabase Realtime (Real-time updates)
- Prometheus (Metrics)

### Supabase Studio

**Description:** Web-based management interface for Supabase database administration.

**Endpoints:**
- Web interface on port 3001

**Documentation:**
- Limited documentation available

**Dependencies:**
- Supabase DB
- Supabase Auth
- Supabase REST

### Grafana

**Description:** Visualization platform for metrics and monitoring data.

**Endpoints:**
- `/api/health` - Health check on port 3002
- Web interface on port 3002

**Documentation:**
- `/docs/monitoring/dashboards.md` - Dashboard documentation

**Dependencies:**
- Prometheus (Metrics source)

## Messaging Services

| Service | Description | Port | Status | Documentation Status | Migration Status | Priority |
|---------|-------------|------|--------|---------------------|-----------------|----------|
| **Pub/Sub Emulator** | Message queue for inter-agent communication | 8085 | ✅ Active | Partial | Complete | Medium |

### Google Cloud Pub/Sub Emulator

**Description:** Messaging service that enables asynchronous communication between agents and services.

**Endpoints:**
- `/v1/projects/.../topics` - Topic management on port 8085

**Documentation:**
- `/docs/api/a2a-protocol.md` - A2A protocol documentation

**Dependencies:**
- None (core infrastructure service)

## Observability Services

| Service | Description | Port | Status | Documentation Status | Migration Status | Priority |
|---------|-------------|------|--------|---------------------|-----------------|----------|
| **Prometheus** | Metrics collection | 9090 | ✅ Active | Minimal | Complete | Medium |
| **Node Exporter** | System metrics | 9100 | ✅ Active | Minimal | Complete | Low |
| **Postgres Exporter** | Database metrics | N/A | ✅ Active | Minimal | Complete | Low |

### Prometheus

**Description:** Metrics collection and monitoring system.

**Endpoints:**
- `/-/healthy` - Health check on port 9090
- Web interface on port 9090

**Documentation:**
- `/docs/monitoring/dashboards.md` - Monitoring documentation

**Dependencies:**
- Node Exporter (System metrics)
- Postgres Exporter (Database metrics)

### Node Exporter

**Description:** System metrics exporter for Prometheus.

**Endpoints:**
- Metrics endpoint on port 9100

**Documentation:**
- Limited documentation available

**Dependencies:**
- Prometheus (Metrics ingestion)

### Postgres Exporter

**Description:** PostgreSQL metrics exporter for Prometheus.

**Endpoints:**
- Internal metrics endpoint

**Documentation:**
- Limited documentation available

**Dependencies:**
- Prometheus (Metrics ingestion)
- Supabase DB (PostgreSQL)

## Service Dependencies

The following diagram illustrates the main service dependencies in the platform:

```
+--------------+    +----------------------+
| Mission      |<-->| Supabase            |
| Control UI   |    | (DB, Auth, REST)    |
+--------------+    +----------------------+
        ^                     ^
        |                     |
        v                     v
+------------------+    +---------------+
| Agent Services   |<-->| Pub/Sub      |
| (Alfred, Social, |    | Emulator     |
| Legal, Financial)|    +---------------+
+------------------+            ^
        ^                       |
        |                       v
        v                +---------------+
+------------------+    | Observability |
| Qdrant          |    | (Prometheus,   |
| Vector Database |    | Grafana)       |
+------------------+    +---------------+
```

## Documentation Migration Status

The following tables provide the status of documentation migration and consolidation for all services:

### Agent Services Documentation

| Service | Documentation Location | Status | Priority | Related Documents |
|---------|------------------------|--------|----------|-------------------|
| Alfred Bot | `/docs/architecture/system-design.md`<br>`/docs/api/a2a-protocol.md` | Complete | Low | `/docs/staging-area/alfred__AI_Assistant/*.md` |
| Social Intelligence | `/docs/agents/social-intelligence-agent.md`<br>`/docs/workflows/niche-scout-implementation-guide.md` | Complete | Low | `/docs/staging-area/Social_Intel/*.md` |
| Legal Compliance | `/docs/agents/legal-compliance-agent.md` | Complete | Low | `/docs/staging-area/AI_Agent_Platform_v2/AI Agent Platform v2- Security Plan*.md` |
| Financial-Tax | `/docs/agents/financial-tax-agent.md`<br>`/docs/agents/financial-tax-deployment-checklist.md` | In Progress | High | N/A |

### Infrastructure Services Documentation

| Service | Documentation Location | Status | Priority | Related Documents |
|---------|------------------------|--------|----------|-------------------|
| Supabase Stack | `/docs/architecture/system-design.md` | Complete | Low | `/docs/staging-area/AI_Agent_Platform_v2/AI Agent Platform v2 – Re-architecture Plan*.md` |
| Redis | Limited documentation | Needed | Medium | N/A |
| Qdrant | `/docs/architecture/system-design.md` | Partial | Medium | N/A |
| Ollama | Limited documentation | Needed | Medium | N/A |

### UI Services Documentation

| Service | Documentation Location | Status | Priority | Related Documents |
|---------|------------------------|--------|----------|-------------------|
| Mission Control | `/docs/phase6-mission-control/requirements.md`<br>`/docs/phase6-mission-control/implementation-plan.md` | In Progress | High | `/docs/staging-area/AI_Agent_Platform_v2/AI Agent Platform v2 Complete Implementation Guide*.md` |
| Supabase Studio | Limited documentation | Needed | Low | N/A |
| Grafana | `/docs/monitoring/dashboards.md` | Minimal | Medium | N/A |

### Messaging Services Documentation

| Service | Documentation Location | Status | Priority | Related Documents |
|---------|------------------------|--------|----------|-------------------|
| Pub/Sub Emulator | `/docs/api/a2a-protocol.md` | Partial | Medium | `/docs/staging-area/AI_Agent_Platform_v2/AI Agent Platform v2 – Re-architecture Plan*.md` |

### Observability Services Documentation

| Service | Documentation Location | Status | Priority | Related Documents |
|---------|------------------------|--------|----------|-------------------|
| Prometheus | `/docs/monitoring/dashboards.md` | Minimal | Medium | N/A |
| Node Exporter | Limited documentation | Needed | Low | N/A |
| Postgres Exporter | Limited documentation | Needed | Low | N/A |

---

**Note**: This document serves as a comprehensive catalog of all services and their documentation status in the Alfred Agent Platform v2. It should be updated regularly as services are added, removed, or modified.

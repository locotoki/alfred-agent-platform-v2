# Alfred Agent Platform v2 - Core Services

This document outlines all of the core services that make up the Alfred Agent Platform v2, including their purpose and startup dependencies.

## Core Infrastructure Services

1. **alfred-postgres** (PostgreSQL database)
   - Primary data store for the platform
   - Required by most other services
   - Should be started first

2. **redis** (In-memory data store)
   - Used for caching, message queuing, and real-time data
   - Required by agent services and RAG
   - Should be started early in the sequence

3. **vector-db** (Qdrant vector database)
   - Stores vector embeddings for RAG capabilities
   - Required by agent-rag
   - Health check depends on curl being installed

4. **pubsub-emulator** (Message queue)
   - Provides asynchronous communication between services
   - Required by agent services

5. **mail-server** (MailHog email service)
   - Handles email notifications and alerts
   - Required for authentication flows
   - Critical component of the core stack

## Database Services (Supabase)

6. **db-auth** (Authentication service)
   - Handles user authentication and authorization
   - Depends on alfred-postgres

7. **db-api** (REST API for database)
   - Provides RESTful access to the PostgreSQL database
   - Depends on alfred-postgres

8. **db-admin** (Database administration UI)
   - Web interface for database management
   - Depends on alfred-postgres and db-api

9. **db-realtime** (Real-time updates)
   - Provides real-time database updates
   - Depends on alfred-postgres

10. **db-storage** (Storage service)
    - Handles file storage and management
    - Depends on alfred-postgres and db-api

## Model Services

11. **alfred-ollama** (Local LLM service)
    - Provides local LLM inference capabilities
    - Used by model-router for local model inference

12. **alfred-model-registry** (Model registration)
    - Manages available LLM models
    - Maintains model metadata and configurations

13. **alfred-model-router** (Model routing)
    - Routes LLM requests to appropriate providers
    - Handles failover and load balancing

## Agent Services

14. **agent-rag** (RAG Gateway)
    - Provides Retrieval-Augmented Generation capabilities
    - Depends on vector-db and redis

15. **agent-core** (Core Agent Framework)
    - Central orchestration for agents
    - Depends on alfred-postgres, redis, and pubsub-emulator

16. **agent-atlas** (Infrastructure Architect)
    - Infrastructure management agent
    - Depends on agent-rag, redis, and pubsub-emulator

17. **agent-social** (Social Intelligence Agent)
    - Social media and content analysis
    - Depends on alfred-postgres, pubsub-emulator, redis, and agent-rag

18. **agent-financial** (Financial Tax Agent)
    - Financial analysis and tax assistance
    - Depends on alfred-postgres, pubsub-emulator, redis, and agent-rag

19. **agent-legal** (Legal Compliance Agent)
    - Legal analysis and compliance checks
    - Depends on alfred-postgres, pubsub-emulator, redis, and agent-rag

## UI Services

20. **ui-admin** (Admin Dashboard)
    - Administrative interface for the platform
    - Depends on agent-core

21. **ui-chat** (Chat Interface)
    - User-facing chat interface
    - Depends on agent-core

22. **auth-ui** (Authentication UI)
    - User login and registration interface
    - Works with db-auth
    - Critical component of the auth system

## Monitoring Services

23. **monitoring-metrics** (Prometheus)
    - Collects and stores metrics
    - Provides monitoring data for dashboards

24. **monitoring-dashboard** (Grafana)
    - Visualizes metrics and logs
    - Provides monitoring UI

25. **monitoring-node** (Node Exporter)
    - Exports system metrics
    - Provides host-level monitoring

26. **monitoring-db** (Postgres Exporter)
    - Exports PostgreSQL metrics
    - Requires authentication to postgres

## Recommended Startup Order

For proper startup, services should be started in the following order:

1. Core Infrastructure (redis, vector-db, pubsub-emulator, alfred-postgres, mail-server)
2. Database Services (db-auth, db-api, db-realtime, db-storage, db-admin)
3. Model Services (alfred-ollama, alfred-model-registry, alfred-model-router)
4. Agent Services (agent-rag, agent-core, agent-atlas, agent-financial, agent-legal, agent-social)
5. UI Services (ui-admin, ui-chat, auth-ui)
6. Monitoring Services (monitoring-metrics, monitoring-dashboard, monitoring-node, monitoring-db)

## Shutdown Order

For proper shutdown, services should be stopped in the reverse order:

1. UI Services
2. Agent Services
3. Model Services
4. Monitoring Services
5. Database Services
6. Mail Service
7. Core Infrastructure

This ordered approach ensures dependencies are properly respected during startup and shutdown.
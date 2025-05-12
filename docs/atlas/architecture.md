# Atlas Architecture Design

*Last Updated: 2025-05-11*  
*Owner: Infra Crew*  
*Status: Active*  

## Overview

Atlas is a stateless Python microservice that functions as the architecture design agent for the Alfred Agent Platform v2. It listens for architecture-related requests on the platform's event bus, retrieves relevant context from a knowledge base, generates architecture specifications using OpenAI GPT models, and publishes the results back to the bus.

This document covers the architecture of Atlas, its components, interactions, and design considerations.

## System Components

![Atlas Architecture](../assets/atlas-arch.png)

### Core Components

1. **Atlas Worker**
   - Stateless Python service that processes requests
   - Consumes messages from `architect_in` topic
   - Produces responses to `architect_out` topic
   - Integrates with OpenAI API for architecture generation

2. **RAG Gateway**
   - Provides retrieval-augmented generation capabilities
   - Maintains embeddings in Qdrant vector database
   - Handles chunking and embedding of documentation
   - Serves context retrieval requests from Atlas

3. **Event Bus**
   - Pub/Sub messaging service for agent communication
   - Ensures reliable message delivery
   - Provides exactly-once semantics
   - Connects Atlas to UI and other agents

4. **State Storage**
   - Supabase PostgreSQL for persistent message storage
   - Maintains history of requests and responses
   - Enables message replay and auditing

5. **Monitoring & Observability**
   - Prometheus metrics collection
   - Grafana dashboards for monitoring
   - Health check endpoints for reliability

## Data Flow

1. **Request Ingestion**
   - Request arrives from UI or Claude-Code via Pub/Sub
   - Message with `role: "architect"` is consumed by Atlas Worker
   - Incoming message is stored in Supabase for persistence

2. **Context Retrieval**
   - Atlas uses the RAG Gateway to fetch relevant documentation
   - Query is embedded and compared to document embeddings
   - Most relevant document chunks are returned to Atlas

3. **Architecture Generation**
   - Context and prompt are sent to OpenAI API
   - If primary model fails, fallback chain is used
   - Generated architecture spec is formatted as markdown

4. **Response Delivery**
   - Response is stored in Supabase for persistence
   - Response is published to `architect_out` topic
   - UI or other agents consume the response

## Code Structure

```
services/
├── atlas-worker/
│   ├── atlas/
│   │   ├── __init__.py
│   │   ├── main.py          # Core application logic
│   │   ├── bus_client.py    # Pub/Sub integration
│   │   ├── openai_client.py # OpenAI API integration
│   │   ├── rag_client.py    # RAG Gateway client
│   │   ├── supabase_client.py # Supabase integration
│   │   └── metrics.py       # Prometheus metrics
│   ├── Dockerfile
│   └── pyproject.toml
└── atlas-rag-gateway/
    ├── rag_gateway/
    │   ├── __init__.py
    │   ├── main.py          # FastAPI application
    │   └── backend.py       # Vector search and embedding
    ├── Dockerfile
    └── pyproject.toml
```

## Deployment Architecture

Atlas is designed to be deployed as a containerized microservice, either on Kubernetes or using Docker Compose. The architecture is stateless, making it easy to scale horizontally by adding more worker instances.

### Development Environment

For development, the system uses Docker Compose with:
- Local Qdrant instance for vector storage
- Redis for caching
- Pub/Sub emulator for messaging
- Optional Supabase connection

### Production Environment

In production, the system can be deployed on:
- GKE or other Kubernetes platform
- Cloud Run or other serverless container platform
- Self-hosted Docker instance

## Integration Points

Atlas integrates with several external systems:

1. **OpenAI API**
   - Used for generating architecture specifications
   - Configurable models with fallback chain
   - Error handling and retry logic

2. **Supabase**
   - Stores messages for persistence
   - Enables message replay and auditing
   - Provides real-time updates to UI

3. **Pub/Sub**
   - Handles message routing between agents
   - Ensures reliable message delivery
   - Supports exactly-once semantics

4. **Prometheus/Grafana**
   - Collects metrics for monitoring
   - Provides dashboards for observability
   - Alerts on system health issues

## Security Considerations

1. **API Key Security**
   - OpenAI API keys are stored securely
   - Keys are rotated regularly
   - Secrets never committed to source control

2. **Data Privacy**
   - PII filtering in prompts
   - Minimal data persistence
   - Adheres to data protection regulations

3. **Rate Limiting**
   - Token budget enforcement
   - Daily usage tracking
   - Circuit breakers for API calls

## Scalability

Atlas is designed to scale horizontally by adding more worker instances. Each worker is stateless and processes messages independently, making it easy to scale to handle increased load.

Key scalability features:
- Stateless architecture for horizontal scaling
- Connection pooling for database access
- Redis caching for performance optimization
- Task processing in separate threads

## Future Enhancements

1. **Hybrid Reranker**
   - Improved relevance of retrieved context
   - Higher quality architecture specifications

2. **Streaming Responses**
   - Real-time streaming of generation results
   - Better user experience for long generations

3. **Multi-Provider Support**
   - Support for alternative LLM providers
   - Reduced dependency on OpenAI

4. **Custom Domain Knowledge**
   - Fine-tuning for specific architecture domains
   - Improved accuracy and relevance
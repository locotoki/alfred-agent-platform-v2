# Atlas System: Infrastructure Architect Agent

Atlas is an AI-powered Infrastructure Architect Agent that designs architecture specifications using Retrieval-Augmented Generation (RAG). It's part of the Alfred Agent Platform v2 and serves as the architectural design component of the Infrastructure Crew.

## System Overview

![Atlas Architecture](docs/assets/atlas-arch.png)

Atlas consists of two primary components:

1. **Atlas Worker**: A stateless Python service that:
   - Listens for architecture requests on the event bus
   - Retrieves relevant knowledge through the RAG Gateway
   - Processes requests using OpenAI models (GPT-4.1 → GPT-4o → GPT-4o-mini fallback chain)
   - Publishes architecture specifications back to the event bus

2. **RAG Gateway**: A FastAPI service that:
   - Manages document embeddings in a vector database (Qdrant)
   - Provides context retrieval for architecture generation
   - Handles document processing and chunking
   - Caches frequently accessed content

## Features

- **Stateless Architecture**: Easy horizontal scaling for increased load
- **Robust Error Handling**: Graceful degradation with fallback chains
- **Comprehensive Monitoring**: Prometheus metrics and Grafana dashboards
- **Advanced RAG System**: Document retrieval with embedding-based search
- **Token Budget Management**: Control costs with configurable limits
- **Health Check Endpoints**: Easy monitoring of system status

## Quick Start

### Prerequisites

- Docker and Docker Compose v2+
- OpenAI API key
- 2+ vCPU and 4+ GB RAM

### Start Atlas System

```bash
# Clone the repository (if not already done)
git clone https://github.com/locotoki/alfred-agent-platform-v2.git
cd alfred-agent-platform-v2

# Set up environment variables
cp .env.example .env
# Edit .env to add your OpenAI API key and other config

# Start Atlas with monitoring
./scripts/start_atlas_with_monitoring.sh

# Index documentation for RAG
./scripts/index_repo.sh docs/

# Send a test request
./scripts/publish_task.sh "Design a microservice logging architecture"

# View the response
docker logs -f atlas-worker | grep architect_out
```

### Monitoring

- Atlas Worker metrics: http://localhost:8000/metrics
- RAG Gateway metrics: http://localhost:8501/metrics
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin)

## Configuration

Configure Atlas using environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENAI_API_KEY` | OpenAI API key | (required) |
| `OPENAI_MODEL` | Primary model to use | gpt-4.1 |
| `OPENAI_FALLBACK_MODELS` | Fallback models | gpt-4o,gpt-4o-mini |
| `TOKEN_BUDGET_PER_RUN` | Max tokens per request | 12000 |
| `DAILY_TOKEN_BUDGET` | Daily token budget | 250000 |
| `SUPABASE_URL` | Supabase instance URL | http://localhost:54321 |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key | (required for production) |
| `PUBSUB_PROJECT_ID` | GCP project ID or emulator namespace | atlas-dev |
| `PUBSUB_TOPIC_IN` | Input topic | architect_in |
| `PUBSUB_TOPIC_OUT` | Output topic | architect_out |
| `RAG_URL` | RAG Gateway URL | http://rag-gateway:8501 |
| `RAG_API_KEY` | API key for RAG Gateway | atlas-key |
| `RAG_COLLECTION` | Collection for architecture knowledge | architecture-knowledge |
| `RAG_TOP_K` | Number of results from RAG | 15 |
| `RELEVANCY_THRESHOLD` | Minimum similarity score | 0.65 |

## Component Documentation

- [Atlas Worker README](services/atlas-worker/README.md): Core worker service details
- [RAG Gateway Documentation](docs/RAG_GATEWAY.md): Context retrieval service details
- [Atlas Architecture](docs/atlas/architecture.md): Detailed system design
- [Atlas API](docs/atlas/api.md): API reference
- [Atlas Operations](docs/atlas/operations.md): Operational guide
- [Atlas Usage Guide](docs/atlas/USAGE_GUIDE.md): User guide

## Message Flow

1. **Request**: Client sends message to `architect_in` topic
   ```json
   {
     "task_id": "uuid4",
     "role": "architect",
     "msg_type": "chat",
     "content": "Design a microservice logging architecture",
     "metadata": {
       "parent_id": null,
       "schema_ver": 1
     }
   }
   ```

2. **Response**: Atlas responds on `architect_out` topic
   ```json
   {
     "task_id": "uuid4",
     "role": "architect",
     "msg_type": "spec",
     "content": "# Microservice Logging Architecture\n\n## Overview\n...",
     "metadata": {
       "tokens": 2450,
       "model": "gpt-4.1",
       "parent_id": "original-task-id",
       "status": "completed",
       "schema_ver": 1
     }
   }
   ```

## Advanced Usage

### Scaling Atlas Workers

Atlas is stateless and can be scaled horizontally by adding more worker instances:

```yaml
# Docker Compose example
services:
  atlas-worker:
    image: atlas-worker:latest
    deploy:
      replicas: 3
```

### Document Indexing

Add documents to the RAG knowledge base:

```bash
# Index a specific directory
./scripts/index_repo.sh path/to/docs

# Process a single document
./scripts/process_docs.py --file path/to/document.md
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Worker not starting | Check OpenAI API key, verify RAG Gateway is accessible |
| High token usage | Reduce `RAG_TOP_K` or switch to a smaller model |
| Slow response times | Check Prometheus metrics, consider scaling worker replicas |
| RAG not finding relevant content | Add more domain-specific documents to the index |

## Next Steps

1. Implement hybrid reranker for better context retrieval
2. Add streaming responses for large generations
3. Support additional LLM providers
4. Fine-tune models for domain-specific knowledge

## Known Issues and Limitations

1. **Message Processing**: In some configurations, messages sent to the Pub/Sub topic may not be immediately processed. Manual retry of the messages might be required.

2. **RAG Gateway Connection**: The RAG Gateway needs to be properly started before the Atlas Worker to ensure successful context retrieval.

3. **Service Dependencies**: The worker requires Supabase, Pub/Sub emulator, and RAG Gateway to be running before it starts. All services should be in the same Docker network to communicate properly.

## References

- [Atlas Deployment Manual](docs/staging-area/Infra_Crew/Atlas_Deployment_Manual_v0.2.md)
- [Atlas MVP Scaffold](docs/staging-area/Infra_Crew/Atlas_MVP_Scaffold_patch‑set_001.md)

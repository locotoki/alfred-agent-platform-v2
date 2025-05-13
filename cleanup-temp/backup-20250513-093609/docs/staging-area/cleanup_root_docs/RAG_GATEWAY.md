# RAG Gateway

The RAG Gateway is a centralized Retrieval-Augmented Generation service that supports all agents in the Alfred Agent Platform v2. This document explains the design, configuration, and usage of this platform-wide service.

## Overview

The RAG Gateway provides context-aware knowledge retrieval for all agents through:

- **Vector-based document retrieval** using Qdrant
- **Document chunking and embedding**
- **Multi-tenant collection management**
- **Agent-specific API access**
- **Caching for performance optimization** with Redis

## Multi-Agent Architecture

![RAG Gateway Architecture](assets/rag-gateway-arch.png)

The RAG Gateway is designed as a shared service that:

1. **Maintains separate knowledge collections** for different agents and domains
2. **Enforces access control** based on agent identity
3. **Provides consistent API access** across the platform
4. **Optimizes resource usage** through shared infrastructure

## Collections

Each agent or domain has one or more dedicated collections:

| Collection Name | Purpose | Primary Users |
|-----------------|---------|---------------|
| general-knowledge | Platform-wide shared knowledge | All agents |
| architecture-knowledge | Infrastructure design patterns | Atlas |
| alfred-personal | Home assistant knowledge | Alfred (personal mode) |
| alfred-business | Business assistant knowledge | Alfred (business mode) |
| financial-knowledge | Finance and tax domain | Financial-Tax agent |
| legal-knowledge | Legal and compliance domain | Legal Compliance agent |
| social-intel-knowledge | Social media intelligence | Social Intel agent |

## Authentication and Access Control

The gateway implements a role-based access control system:

1. **API Keys**: Each agent has a specific API key for authentication
2. **Access Policies**: Define which collections each agent can access
3. **Rate Limiting**: Prevents any single agent from overwhelming the service
4. **Usage Tracking**: Monitors and logs agent usage patterns

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `QDRANT_URL` | Qdrant vector database URL | http://qdrant:6333 |
| `REDIS_URL` | Redis caching server URL | redis://redis:6379/0 |
| `DEFAULT_COLLECTION` | Default collection name | general-knowledge |
| `ENABLE_COLLECTIONS` | Enable multi-collection support | true |
| `AUTH_ENABLED` | Enable API key authentication | true |
| `API_KEYS` | Comma-separated agent:key pairs | atlas:atlas-key,... |
| `RATE_LIMIT_REQUESTS` | Max requests per window | 100 |
| `RATE_LIMIT_WINDOW_SECONDS` | Rate limit window size | 60 |
| `LOG_LEVEL` | Logging verbosity | INFO |
| `LOG_AGENT_ACCESS` | Log agent access patterns | true |

### Collection Configuration

Collections are defined in `config/rag/collections.json`:

```json
{
  "collections": [
    {
      "name": "collection-name",
      "description": "Collection purpose",
      "embedding_model": "model-name",
      "chunk_size": 512,
      "chunk_overlap": 50,
      "metadata_filters": ["filter1", "filter2"]
    }
  ]
}
```

### Access Control Configuration

Access policies are defined in `config/rag/access_control.json`:

```json
{
  "policies": [
    {
      "agent": "agent-name",
      "allowed_collections": ["collection1", "collection2"],
      "rate_limit_requests": 200,
      "read_only": false,
      "can_ingest": true
    }
  ]
}
```

## API Usage for Agents

### Authentication

All requests must include the agent's API key:

```bash
curl -X POST http://rag-gateway:8501/query \
  -H "Content-Type: application/json" \
  -H "X-API-Key: agent-specific-key" \
  -d '{"query": "architecture patterns", "collection": "architecture-knowledge"}'
```

### Query Endpoint

Retrieve context for a specific query:

```bash
curl -X POST http://rag-gateway:8501/query \
  -H "Content-Type: application/json" \
  -H "X-API-Key: agent-specific-key" \
  -d '{
    "query": "user question",
    "collection": "agent-specific-collection",
    "top_k": 5,
    "filter": {"metadata_field": "value"}
  }'
```

### Ingest Endpoint

Add documents to a collection:

```bash
curl -X POST http://rag-gateway:8501/ingest \
  -H "Content-Type: application/json" \
  -H "X-API-Key: agent-specific-key" \
  -d '{
    "documents": [
      {
        "text": "document content",
        "metadata": {"source": "file.md", "domain": "architecture"}
      }
    ],
    "collection": "agent-specific-collection"
  }'
```

### Health Check

Check service health:

```bash
curl http://rag-gateway:8501/healthz
```

## Integration with Agents

### Agent Environment Variables

Each agent should configure:

1. **RAG Gateway URL**: `RAG_URL=http://rag-gateway:8501`
2. **API Key**: `RAG_API_KEY=agent-specific-key`
3. **Default Collection**: `RAG_COLLECTION=agent-specific-collection`

### Example Configuration for Atlas Worker

```yaml
atlas-worker:
  environment:
    RAG_URL: http://rag-gateway:8501
    RAG_API_KEY: atlas-key
    RAG_COLLECTION: architecture-knowledge
```

### Example for Dual-Personality Agents (Alfred)

```python
# Python code example for switching collections based on personality mode
def get_rag_context(query, personality_mode="business"):
    collection = "alfred-business" if personality_mode == "business" else "alfred-personal"
    
    response = requests.post(
        f"{os.environ.get('RAG_URL')}/query",
        headers={
            "Content-Type": "application/json",
            "X-API-Key": os.environ.get('RAG_API_KEY')
        },
        json={
            "query": query,
            "collection": collection
        }
    )
    
    return response.json()
```

## Document Indexing

### General Platform Knowledge

```bash
# Index shared platform documentation
./scripts/index_documents.sh general-knowledge /path/to/platform/docs
```

### Agent-Specific Knowledge

```bash
# Index Atlas-specific documentation
./scripts/index_documents.sh architecture-knowledge /path/to/architecture/docs

# Index Alfred personal assistant documentation
./scripts/index_documents.sh alfred-personal /path/to/personal/docs

# Index Alfred business assistant documentation
./scripts/index_documents.sh alfred-business /path/to/business/docs
```

## Monitoring and Management

### Metrics Endpoint

View service metrics:

```bash
curl http://rag-gateway:8501/metrics
```

### Collection Management

List all collections:

```bash
curl http://rag-gateway:8501/collections \
  -H "X-API-Key: admin-key"
```

Create a new collection:

```bash
curl -X POST http://rag-gateway:8501/collections/create \
  -H "Content-Type: application/json" \
  -H "X-API-Key: admin-key" \
  -d '{
    "name": "new-collection",
    "description": "Purpose of new collection"
  }'
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Authentication failures | Verify agent API key matches configuration |
| Collection not found | Ensure collection is created and agent has access |
| Rate limit exceeded | Check rate limit configuration and agent usage |
| Query returning irrelevant results | Adjust embedding model or chunk size |
| Slow response times | Check Redis caching and consider scaling resources |

## Migration from Atlas-Specific RAG

If you previously used the Atlas-specific RAG Gateway, follow these steps to migrate:

1. Update service references from `atlas-rag-gateway` to `rag-gateway`
2. Update environment variables in agent configurations
3. Add API keys for authentication
4. Specify collections for each agent
5. Re-index documents into appropriate collections

## Extending the RAG Gateway

The gateway can be extended with:

1. **Custom embedding models** for domain-specific knowledge
2. **Advanced retrieval algorithms** like hybrid search or re-ranking
3. **Integration with other vector databases** beyond Qdrant
4. **Custom preprocessing pipelines** for specialized document types

## Reference Implementation

For detailed implementation details, refer to the `rag-gateway` code and configuration files in the repository.
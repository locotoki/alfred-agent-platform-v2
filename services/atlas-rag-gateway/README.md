# Atlas RAG Gateway

## Overview

The RAG Gateway provides retrieval-augmented generation services for the Atlas architecture agent, allowing it to access relevant knowledge when generating architecture specifications.

## Architecture

The service follows a simple API design:

- `main.py`: FastAPI application and endpoints
- `backend.py`: Core RAG functionality

## Development

### Prerequisites

- Python 3.11+
- Poetry 1.8+
- Docker and Docker Compose

### Setup

```bash
# Install dependencies
cd services/atlas-rag-gateway
poetry install --no-root

# Generate lock file
poetry lock
```

### Running Locally

To run the RAG Gateway outside Docker for development:

```bash
export PYTHONPATH=$PYTHONPATH:$(pwd)
export QDRANT_URL=http://localhost:6333
export REDIS_URL=redis://localhost:6379/0
# Set other required environment variables

poetry run uvicorn rag_gateway.main:app --host 0.0.0.0 --port 8501 --reload
```

## API Endpoints

- `GET /healthz`: Health check endpoint
- `POST /v1/query_chat`: Retrieve relevant context for a question
- `POST /v1/embed_batch`: Embed a batch of documents

## Dependencies

- `fastapi`: Web framework
- `uvicorn`: ASGI server
- `qdrant-client`: Vector database client
- `sentence-transformers`: Embedding models
- `redis`: Caching
- `prometheus-client`: Metrics collection

## Configuration

The service is configured through environment variables:

- `QDRANT_URL`: URL of Qdrant vector database
- `REDIS_URL`: URL of Redis cache
- `COLLECTION_NAME`: Qdrant collection name (default: "atlas-docs")
- `EMBEDDING_MODEL`: Sentence Transformers model (default: "all-MiniLM-L6-v2")

## Production Implementation

To implement the full RAG Gateway:

1. Replace the stub `backend.py` with real vector DB integration
2. Add proper caching with Redis
3. Implement batched embedding processing
4. Add more comprehensive error handling
5. Add proper metrics collection
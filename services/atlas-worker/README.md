# Atlas Worker

## Overview

Atlas Worker is the core component of the Atlas architecture agent that processes architecture requests and generates specifications.

## Architecture

The worker follows a modular design:

- `main.py`: Entry point and main event loop
- `bus_client.py`: Handles Pub/Sub communication
- `rag_client.py`: Interfaces with the RAG Gateway
- `openai_client.py`: Manages OpenAI API calls
- `metrics.py`: Prometheus metrics

## Development

### Prerequisites

- Python 3.11+
- Poetry 1.8+
- Docker and Docker Compose

### Setup

```bash
# Install dependencies
cd services/atlas-worker
poetry install --no-root

# Generate lock file
poetry lock
```

### Running Locally

To run the worker outside Docker for development:

```bash
export PYTHONPATH=$PYTHONPATH:$(pwd)
export OPENAI_API_KEY=your-key-here
export RAG_URL=http://localhost:8501
# Set other required environment variables

poetry run python -m atlas.main
```

## Testing

Tests can be run using pytest:

```bash
poetry run pytest
```

## Dependencies

- `google-cloud-pubsub`: For message bus communication
- `openai`: For OpenAI API calls
- `httpx`: For HTTP requests to RAG Gateway
- `prometheus-client`: For metrics collection
- `tenacity`: For retry logic
- `asyncio`: For async event loop

## Configuration

The worker is configured through environment variables:

- `OPENAI_API_KEY`: OpenAI API key
- `SUPABASE_URL`: URL of Supabase instance
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key for Supabase
- `PUBSUB_PROJECT_ID`: GCP project ID for Pub/Sub
- `PUBSUB_TOPIC_IN`: Input topic
- `PUBSUB_TOPIC_OUT`: Output topic
- `PUBSUB_EMULATOR_HOST`: Pub/Sub emulator host (development only)
- `RAG_URL`: URL of RAG Gateway

## Metrics

The worker exposes Prometheus metrics on port 8000:

- `atlas_tokens_total`: Counter of tokens used
- `atlas_run_seconds`: Histogram of request processing times
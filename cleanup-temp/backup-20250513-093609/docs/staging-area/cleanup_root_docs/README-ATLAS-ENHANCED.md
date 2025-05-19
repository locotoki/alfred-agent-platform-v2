# Enhanced Atlas Implementation

This implementation of the Atlas (Infra-Architect Agent) includes several enhancements beyond the basic MVP scaffold, making it more robust, observable, and easier to use in both development and production environments.

## Overview

Atlas is a stateless Python worker that:

1. Listens for **`architect`**-role messages on the event-bus.
2. Retrieves relevant knowledge through the **RAG Service**.
3. Calls the configured OpenAI model (GPT-4.1 → o3 → o1-pro fallback chain).
4. Publishes architecture specs back to the bus for Claude-Code and UI clients.

## Enhanced Features

The enhanced implementation includes:

### 1. Robust OpenAI Integration
- Full fallback chain (GPT-4.1 → GPT-4o → GPT-4o-mini)
- Token usage tracking and budget enforcement
- Retry logic with exponential backoff
- Error handling and graceful degradation

### 2. Improved RAG System
- Advanced document processing with smart chunking
- Qdrant vector database integration
- Redis caching for frequently accessed content
- Multi-threaded document indexing

### 3. Comprehensive Monitoring
- Prometheus metrics collection
- Grafana dashboards
- Alert rules for critical conditions
- Detailed health checks

### 4. Supabase Integration
- Automatic table creation and management
- Message persistence and history
- Proper Row-Level Security (RLS)
- Error handling for disconnected operations

### 5. Developer Experience
- Enhanced Make commands
- Detailed documentation
- Powerful document processing tools
- Simplified deployment options

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Python 3.11+ (for local development)
- OpenAI API key
- Supabase URL and service role key (optional)

### Quick Start

1. **Set up environment variables**

   Copy the example environment file and add your OpenAI API key:
   ```bash
   cp .env.dev.example .env.dev
   # Edit .env.dev to add your OpenAI API key
   ```

2. **Start Atlas with monitoring**

   This will start Atlas worker, RAG gateway, Prometheus, and Grafana:
   ```bash
   make atlas-monitor
   ```

3. **Set up Supabase tables** (optional)

   If you want to use Supabase for message persistence:
   ```bash
   make atlas-setup-supabase
   ```

4. **Index documents**

   Add documents to the RAG knowledge base:
   ```bash
   make atlas-index PATH=/path/to/docs
   ```

5. **Send a test task**

   Request an architecture specification:
   ```bash
   make atlas-publish MSG="Design a logging system for microservices"
   ```

6. **Monitor the system**

   - Grafana: http://localhost:3000 (admin/admin)
   - Prometheus: http://localhost:9090
   - RAG Gateway: http://localhost:8501/healthz
   - Atlas Worker: http://localhost:8000/healthz

## Makefile Commands

The following Make commands are available:

- `atlas-dev` - Start Atlas development stack
- `atlas-down` - Stop Atlas development stack
- `atlas-monitor` - Start Atlas with full monitoring (Prometheus, Grafana)
- `atlas-index PATH=` - Index documents for Atlas RAG
- `atlas-publish MSG=` - Publish a task to Atlas
- `atlas-setup-supabase` - Set up Supabase tables for Atlas

## Configuration Options

The system can be configured using the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENAI_API_KEY` | OpenAI API key | (required) |
| `OPENAI_MODEL` | Primary model to use | gpt-4.1 |
| `OPENAI_FALLBACK_MODELS` | Comma-separated fallback models | gpt-4o,gpt-4o-mini |
| `TOKEN_BUDGET_PER_RUN` | Maximum tokens per request | 12000 |
| `DAILY_TOKEN_BUDGET` | Daily token budget | 250000 |
| `SUPABASE_URL` | Supabase instance URL | http://localhost:54321 |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key | (optional) |
| `PUBSUB_PROJECT_ID` | GCP project ID or emulator namespace | atlas-dev |
| `PUBSUB_TOPIC_IN` | Input topic | architect_in |
| `PUBSUB_TOPIC_OUT` | Output topic | architect_out |
| `RAG_URL` | RAG Gateway URL | http://localhost:8501 |
| `RAG_TOP_K` | Number of results from RAG | 15 |
| `RELEVANCY_THRESHOLD` | Minimum similarity score | 0.65 |

## Advanced Document Indexing

The enhanced document processor provides more options for indexing content:

```bash
./scripts/process_docs.py --help
```

Features include:
- Smart chunking based on document structure
- Multi-threaded processing for faster indexing
- Metadata extraction from documents
- Support for various file types

## Production Deployment

For production deployments:

1. Use Docker/Kubernetes secrets for API keys
2. Set appropriate resource limits
3. Configure proper monitoring and alerting
4. Set up real-time backup for Supabase
5. Implement proper scaling based on load

## Monitoring

The Grafana dashboard includes:
- Token usage and budget tracking
- Latency metrics (p50, p95, p99)
- Service health status
- RAG performance metrics

Alerts are configured for:
- High token usage (>80% of budget)
- High latency (p95 > 10s)
- Service unavailability (RAG, OpenAI, Supabase)

## Documentation

For more information, see:
- [Atlas Architecture](./docs/atlas/architecture.md)
- [API Reference](./docs/atlas/api.md)
- [Operations Guide](./docs/atlas/operations.md)
- [Usage Guide](./docs/atlas/usage-guide.md)

## Next Steps

Potential further enhancements:
1. Implement hybrid reranker for better context retrieval
2. Add streaming responses for large generations
3. Support for additional LLM providers
4. Fine-tuning for domain-specific architecture knowledge

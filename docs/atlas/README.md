# Atlas (Infra-Architect Agent)

*Last Updated: 2025-05-11*  
*Owner: Infra Crew*  
*Status: MVP Implementation*

## Overview

Atlas is a stateless Python worker that:

1. Listens for **`architect`**-role messages on the event-bus.
2. Retrieves relevant knowledge through the **RAG Service**.
3. Calls the configured OpenAI model (GPT-4.1 → o3 → o1-pro fallback chain).
4. Publishes architecture specs back to the bus for Claude-Code and UI clients.

## Quick Start

The MVP scaffold provides an easy way to run Atlas in a development environment:

```bash
# 1. Create a .env.dev file with required environment variables
cp .env.dev.example .env.dev
# Edit .env.dev to add your OpenAI API key

# 2. Start the Atlas development stack
make atlas-dev

# 3. Send a test task to Atlas
make atlas-publish MSG="Design a minimal CI pipeline"

# 4. Watch the Atlas worker logs
docker logs -f $(docker compose -f docker-compose.dev.yml ps -q atlas-worker)
```

## Architecture

Atlas follows a modular architecture:

- **Atlas Worker**: Core service that processes architecture tasks
- **RAG Gateway**: Provides knowledge retrieval capabilities
- **Event Bus**: Pub/Sub for communication with other agents
- **State Storage**: Supabase for persisting messages

## Required Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `OPENAI_API_KEY` | Authentication for OpenAI API | `sk-...` |
| `SUPABASE_URL` | Supabase instance URL | `http://localhost:54321` |
| `SUPABASE_SERVICE_ROLE_KEY` | Auth key for Supabase | `eyJh...` |
| `PUBSUB_PROJECT_ID` | GCP project or emulator namespace | `atlas-dev` |
| `PUBSUB_TOPIC_IN` | Input topic | `architect_in` |
| `PUBSUB_TOPIC_OUT` | Output topic | `architect_out` |

## Development

The MVP scaffold provides stub implementations of key components to help you get started. To implement a fully functional Atlas agent:

1. Replace the stub RAG implementation with Qdrant + Sentence Transformers
2. Replace the stub OpenAI implementation with a proper OpenAI API client
3. Add metrics collection and monitoring
4. Implement proper error handling and retries

See the [Atlas Deployment Manual](../staging-area/Infra_Crew/atlas_deployment_manual_v0.2.md) for more details on the complete implementation.

## Related Documentation

- [Atlas Deployment Manual](../staging-area/Infra_Crew/atlas_deployment_manual_v0.2.md)
- [Atlas API Reference](./api.md)
- [A2A Protocol Documentation](../api/a2a-protocol.md)
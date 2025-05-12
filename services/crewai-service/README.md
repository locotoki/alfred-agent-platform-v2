# CrewAI Service for Alfred Agent Platform

## Overview

The CrewAI service provides multi-agent orchestration capabilities for the Alfred Agent Platform, building on the CrewAI framework. It enables complex agent collaborations through specialized teams ("crews") of agents, each with different roles and capabilities working together to accomplish tasks.

## Key Features

- **Pre-defined Crew Templates**: Ready-to-use crew configurations for common tasks:
  - Research Crew: In-depth information gathering and analysis
  - Code Review Crew: Multi-perspective code evaluation
  - Data Analysis Crew: Comprehensive data processing and insights

- **Asynchronous Execution**: Background processing of tasks via PubSub message bus
  
- **Platform Integration**: Seamless integration with other Alfred services:
  - RAG Gateway for knowledge retrieval
  - Supabase for persistent storage
  - PubSub for message passing
  - Prometheus for metrics

- **REST API**: Complete API for crew management and task execution

## Architecture

The service is designed with the following components:

1. **FastAPI Application**: HTTP API for crew management
2. **PubSub Subscriber**: Background service for asynchronous task processing
3. **Crew Registry**: Central registration for available crew templates
4. **Base Crew**: Abstract class for all crew implementations
5. **Specialized Crews**: Implementations for specific use cases
6. **Prometheus Metrics**: Performance and utilization monitoring

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check endpoint |
| `/crews` | GET | List available crew types |
| `/crews/{crew_type}/tasks` | POST | Create a new task for a specific crew type |
| `/tasks/{task_id}` | GET | Check the status of a specific task |
| `/metrics` | GET | Prometheus metrics information |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CREWAI_PORT` | HTTP API port | 9004 |
| `CREWAI_METRICS_PORT` | Prometheus metrics port | 9005 |
| `CREWAI_LOG_LEVEL` | Logging level | INFO |
| `CREWAI_OPENAI_API_KEY` | OpenAI API key | Inherited from `ALFRED_OPENAI_API_KEY` |
| `CREWAI_ANTHROPIC_API_KEY` | Anthropic API key | Inherited from `ALFRED_ANTHROPIC_API_KEY` |
| `ALFRED_PROJECT_ID` | GCP project ID | alfred-agent-platform |
| `ALFRED_PUBSUB_EMULATOR_HOST` | PubSub emulator host | pubsub-emulator:8085 |
| `ALFRED_RAG_URL` | RAG Gateway URL | http://agent-rag:8501 |
| `ALFRED_RAG_API_KEY` | RAG Gateway API key | crew-key |

## PubSub Topics

| Topic | Description |
|-------|-------------|
| `crew.tasks` | Incoming tasks for CrewAI service |
| `crew.results` | Results from completed CrewAI tasks |

## Docker Image

The CrewAI service is packaged as a Docker container with the following specifications:

- Base Image: `python:3.11-slim`
- Exposed Ports: 9004 (API), 9005 (Metrics)
- Health Check: `curl -f http://localhost:9004/health`

## Monitoring

Prometheus metrics available on port 9005:

- `crewai_tasks_total`: Counter of tasks processed (labeled by crew_type, status)
- `crewai_task_duration_seconds`: Histogram of task processing time
- `crewai_api_requests_total`: Counter of API requests
- `crewai_active_tasks`: Gauge of currently active tasks

## Example Usage

### Creating a task via API

```bash
curl -X POST http://localhost:9004/crews/research/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "task_id": "research-task-123",
    "tenant_id": "client-abc",
    "content": {
      "objective": "Research the latest developments in quantum computing",
      "process_type": "sequential"
    }
  }'
```

### Getting task status

```bash
curl http://localhost:9004/tasks/research-task-123
```

## Integration with n8n

The CrewAI service can be triggered from n8n workflows using the HTTP Request node:

1. Use an HTTP Request node pointing to the `/crews/{crew_type}/tasks` endpoint
2. Format the request body according to the crew type requirements
3. Process the response to get the task ID for status tracking

See the example workflows in the `/workflows/n8n/` directory for working examples.

## Development

### Adding a New Crew

1. Create a new file in `crewai_service/crews/` following the pattern of existing crews
2. Implement the crew by extending `BaseCrew`
3. Register the crew in `crewai_service/crews/registry.py`
4. Restart the service

### Running Locally

```bash
# Install dependencies
pip install -r requirements.txt

# Run the service
python -m crewai_service.main
```

### Testing

```bash
pytest tests/
```
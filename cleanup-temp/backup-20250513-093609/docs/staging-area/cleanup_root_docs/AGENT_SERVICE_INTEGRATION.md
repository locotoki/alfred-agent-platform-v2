# Agent Service Integration Guide

This document outlines the process of integrating agent services into the Alfred Agent Platform v2 using the unified Docker Compose environment.

## Recent Fixes Applied

We addressed and fixed the following issues with the agent-financial and agent-legal services:

1. **Missing dependencies**: Added PyJWT to service Dockerfiles
2. **FastAPI route response model issues**: Added `response_model=None` to route decorators to prevent FastAPI from attempting to infer response models
3. **Docker networking**: Set alfred-network as external in docker-compose.yml
4. **Service dependencies**: Ensured proper startup order by waiting for PostgreSQL to be ready

## Integration Requirements for New Agent Services

When adding a new agent service to the platform, ensure the following:

### 1. Dockerfile Requirements

Each agent service should have a Dockerfile that:

- Uses Python 3.11+ (`FROM python:3.11-slim`)
- Installs system dependencies (`build-essential`, `curl`)
- Installs PyJWT explicitly (`RUN pip install --no-cache-dir PyJWT==2.8.0`)
- Includes a proper healthcheck
- Mounts agent and libs directories as volumes

Example:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir PyJWT==2.8.0

# Copy application code
COPY app app/

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Expose port
EXPOSE 9xxx

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:9xxx/health/ || exit 1

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "9xxx"]
```

### 2. FastAPI Application Setup

When creating FastAPI applications for agent services:

- Use `response_model=None` for all API route decorators to prevent response model inference issues
- Implement a /health endpoint that returns a JSON response with status information
- Use consistent error handling patterns
- Initialize proper logging with structlog

Example:
```python
@app.post("/api/v1/agent-name/endpoint", response_model=None)
async def endpoint_handler(request: RequestModel):
    # Implementation
    return {"status": "accepted", "task_id": task_id}
```

### 3. Docker Compose Configuration

In the docker-compose.yml file:

- Include required environment variables
- Mount shared volumes for agents and libs directories
- Add healthchecks for monitoring service health
- Set proper dependencies on core services
- Connect to the alfred-network

Example:
```yaml
agent-name:
  build:
    context: ./services/agent-name
  container_name: agent-name
  ports:
    - "9xxx:9xxx"
  volumes:
    - ./agents:/app/agents
    - ./libs:/app/libs
  environment:
    - DATABASE_URL=postgresql://postgres:your-super-secret-password@db-postgres:5432/postgres
    - REDIS_URL=redis://redis:6379
    # Other environment variables...
  healthcheck:
    test: ["CMD-SHELL", "curl -f http://localhost:9xxx/health/ || exit 1"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 5s
  depends_on:
    db-postgres:
      condition: service_healthy
    redis:
      condition: service_started
    # Other dependencies...
  restart: unless-stopped
  networks:
    - alfred-network
```

### 4. Agent Module Requirements

For agent modules under the agents/ directory:

- Define intent constants at the module level to avoid import issues
- Use consistent class structure for agent implementations
- Initialize agents with required transports and middleware

Example:
```python
# Intent constants - define at module level
MY_INTENT_1 = "my_intent_1"
MY_INTENT_2 = "my_intent_2"

class MyAgent:
    def __init__(self, pubsub_transport, supabase_transport, policy_middleware):
        self.pubsub_transport = pubsub_transport
        self.supabase_transport = supabase_transport
        self.policy_middleware = policy_middleware
        self.supported_intents = [MY_INTENT_1, MY_INTENT_2]
```

## Starting and Monitoring Services

To start agent services and their dependencies:

```bash
# Create network if it doesn't exist
docker network create alfred-network

# Start core dependencies
docker-compose up -d redis db-postgres pubsub-emulator

# Wait for PostgreSQL to be ready
sleep 10
docker-compose exec db-postgres pg_isready -U postgres

# Start agent services
docker-compose up -d agent-name
```

To check service health:

```bash
# Check service is running
docker ps | grep agent-name

# Check logs
docker-compose logs --tail=20 agent-name

# Check health endpoint
curl -s http://localhost:9xxx/health/
```

## Troubleshooting Common Issues

1. **Missing JWT module**: Ensure PyJWT is installed in the Dockerfile
2. **FastAPI response model errors**: Add `response_model=None` to route decorators
3. **Service dependencies not ready**: Use proper depends_on configurations and healthchecks
4. **Network issues**: Ensure all services are on the alfred-network
5. **Missing intent constants**: Define intent constants at the module level

## Additional Resources

- See the Dockerfiles in services/financial-tax and services/legal-compliance for reference implementations
- Check the FastAPI documentation for more details on response models: https://fastapi.tiangolo.com/tutorial/response-model/

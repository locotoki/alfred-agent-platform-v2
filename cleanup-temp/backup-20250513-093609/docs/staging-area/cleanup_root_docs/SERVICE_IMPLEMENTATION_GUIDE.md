# Alfred Agent Platform v2 - Service Implementation Guide

This guide explains how to implement services with the new Docker Compose structure. The refactoring project has established a standardized approach for defining, building, and deploying services within the Alfred Agent Platform.

## Directory Structure

Services in the Alfred platform follow this standard directory structure:

```
services/
├── <service-name>/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py
│   │   ├── models/
│   │   ├── routers/
│   │   ├── services/
│   │   └── utils/
│   ├── tests/
│   │   └── test_*.py
│   ├── Dockerfile
│   ├── Dockerfile.dev
│   ├── requirements.txt
│   └── README.md
```

## Required Files

Each service must include the following files:

### 1. Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE <service-port>

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "<service-port>"]
```

### 2. Dockerfile.dev

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE <service-port>

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "<service-port>", "--reload"]
```

### 3. requirements.txt

List all dependencies for your service:

```
fastapi==0.100.0
uvicorn==0.22.0
pydantic<2.0.0,>=1.8.0  # For compatibility with older libraries
httpx==0.24.1
python-dotenv==1.0.0
# Additional service-specific dependencies
```

### 4. app/main.py

At minimum, each service should implement a health check endpoint:

```python
from fastapi import FastAPI
import os

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Welcome to <Service Name>"}

@app.get("/health")
async def health():
    return {"status": "healthy"}
```

## Docker Compose Integration

Services are defined in the main `docker-compose.yml` file and can be customized through environment-specific overrides (dev/prod) and component-specific overrides.

### Service Definition Template

```yaml
# In docker-compose.yml
services:
  my-service:
    build:
      context: ./services/my-service
      dockerfile: Dockerfile
    image: my-service:latest
    container_name: my-service
    ports:
      - "<host-port>:<container-port>"
    environment:
      - ALFRED_ENVIRONMENT=${ALFRED_ENVIRONMENT:-development}
      - ALFRED_DEBUG=${ALFRED_DEBUG:-true}
      # Additional environment variables
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:<container-port>/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    depends_on:
      # List dependencies
      redis:
        condition: service_started
    restart: unless-stopped
    networks:
      - alfred-network
```

### Development Overrides

In `docker-compose.dev.yml`, add development-specific settings:

```yaml
services:
  my-service:
    # Development build
    build:
      context: ./services/my-service
      dockerfile: Dockerfile.dev
    # Bind mount for development hot reloading
    volumes:
      - ./services/my-service:/app
    # Development-specific environment variables
    environment:
      - ALFRED_LOG_LEVEL=DEBUG
      - ALFRED_RELOAD=true
    # Development command for hot reloading
    command: uvicorn app.main:app --host 0.0.0.0 --port <port> --reload
```

## Environment Variables

The platform uses standardized environment variable naming:

- `ALFRED_*` - Platform-wide variables
- `<SERVICE>_*` - Service-specific variables

Core variables include:

- `ALFRED_ENVIRONMENT` - Current environment (development, production)
- `ALFRED_DEBUG` - Enable debug mode
- `ALFRED_LOG_LEVEL` - Logging level
- `ALFRED_DATABASE_URL` - Database connection string
- `ALFRED_REDIS_URL` - Redis connection string
- `ALFRED_PUBSUB_EMULATOR_HOST` - PubSub emulator host

## Health Checks

All services must implement a health check endpoint at `/health` that returns:

```json
{
  "status": "healthy"
}
```

Docker Compose configurations should include a health check that tests this endpoint:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:<port>/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 10s
```

## Starting Your Service

Use the `alfred.sh` script to manage your services:

```bash
# Start your service in development mode
./alfred.sh start --env=dev --components=<component> --service=<service-name>

# Check logs
./alfred.sh logs --service=<service-name>

# Get shell access
./alfred.sh exec --service=<service-name> bash
```

## Testing

Services should include tests that can be run within the Docker environment:

```bash
# Run tests for a specific service
./alfred.sh exec --service=<service-name> pytest
```

## Best Practices

1. **Standard API Design**: Follow RESTful API design principles.
2. **Rate Limiting**: Implement rate limiting for public-facing endpoints.
3. **Authentication**: Use platform authentication mechanisms.
4. **Logging**: Use structured logging for better observability.
5. **Metrics**: Expose Prometheus metrics for monitoring.
6. **Environment Variables**: Never hardcode secrets or configuration.
7. **Health Checks**: Implement comprehensive health checks.
8. **Docker Optimization**: Use multi-stage builds and optimize image size.

## Example Implementation

See example implementations in:
- `services/alfred-core/` - Core agent service
- `services/rag-service/` - RAG (Retrieval Augmented Generation) service

These services demonstrate the standard structure and requirements for Alfred platform services.
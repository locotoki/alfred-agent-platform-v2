# Low-Hanging Fruit Optimization Guide

This guide provides step-by-step instructions for implementing the lowest-risk, highest-impact optimizations for the Alfred Agent Platform.

## 1. Container Resource Limits (OPT-001)

**Impact**: High - Prevents resource starvation and OOM kills
**Risk**: Low - Can be adjusted if too restrictive

### Implementation

1. Add the following resource limits to `docker-compose.unified.yml`:

```yaml
# RAG Agent (highest memory consumer)
agent-rag:
  # ... existing config
  deploy:
    resources:
      limits:
        memory: 700M
        cpus: '0.5'
      reservations:
        memory: 400M

# Core services
model-registry:
  # ... existing config
  deploy:
    resources:
      limits:
        memory: 150M
        cpus: '0.3'

db-postgres:
  # ... existing config
  deploy:
    resources:
      limits:
        memory: 300M
        cpus: '1.0'
      reservations:
        memory: 100M

# Agents
agent-social:
  # ... existing config
  deploy:
    resources:
      limits:
        memory: 150M
        cpus: '0.3'

agent-financial:
  # ... existing config
  deploy:
    resources:
      limits:
        memory: 150M
        cpus: '0.3'

agent-legal:
  # ... existing config
  deploy:
    resources:
      limits:
        memory: 150M
        cpus: '0.3'
```

2. Apply changes and monitor:
```bash
docker-compose -f docker-compose.unified.yml up -d --force-recreate
```

3. Check for any services restarting due to resource constraints:
```bash
docker ps -a | grep Restarting
```

## 2. Standardize Health Checks (OPT-002)

**Impact**: High - Improves reliability and monitoring
**Risk**: Low - Non-invasive operation

### Implementation

Create a simple health check standardization script:

```bash
#!/bin/bash
# standardize-health-checks.sh

# Backup the original file
cp docker-compose.unified.yml docker-compose.unified.yml.bak

# Update health checks for agent services
for service in agent-financial agent-legal agent-social agent-rag agent-core agent-atlas; do
  # Extract the current port from the service configuration
  port=$(grep -A20 "^  $service:" docker-compose.unified.yml | grep -oP "ports.*?:\K\d+" | head -1)
  
  if [ -n "$port" ]; then
    # Update the health check
    sed -i "/^  $service:/,/healthcheck:/c\\
  $service:\\
    # ... existing config until healthcheck\\
    healthcheck:\\
      test: [\"CMD-SHELL\", \"wget -q --spider http://localhost:$port/health/live || wget -q --spider http://localhost:$port/health || exit 1\"]\\
      interval: 20s\\
      timeout: 5s\\
      retries: 3\\
      start_period: 30s" docker-compose.unified.yml
  fi
done

echo "Updated health checks in docker-compose.unified.yml"
```

Save this script and make it executable:
```bash
chmod +x standardize-health-checks.sh
```

## 3. Startup Sequence Optimization (OPT-004)

**Impact**: High - Reduces startup failures
**Risk**: Low - Only affects initialization

### Implementation

Update the `depends_on` conditions for key services in `docker-compose.unified.yml`:

```yaml
# Financial Tax Agent
agent-financial:
  # ... existing config
  depends_on:
    db-postgres:
      condition: service_healthy
    redis:
      condition: service_healthy
    pubsub-emulator:
      condition: service_started
    model-router:
      condition: service_started
    agent-rag:
      condition: service_started

# Legal Compliance Agent
agent-legal:
  # ... existing config
  depends_on:
    db-postgres:
      condition: service_healthy
    redis:
      condition: service_healthy
    pubsub-emulator:
      condition: service_started
    model-router:
      condition: service_started
    agent-rag:
      condition: service_started

# Model Router
model-router:
  # ... existing config
  depends_on:
    model-registry:
      condition: service_healthy
    llm-service:
      condition: service_started
```

## 4. Environment Variable Cleanup (OPT-005)

**Impact**: Medium - Improves maintainability
**Risk**: Very Low - Documentation improvement

### Implementation

1. Create a standardized `.env.example` file:

```bash
# .env.example

# Database Configuration
DB_USER=postgres
DB_PASSWORD=your-super-secret-password
DB_NAME=postgres
DB_JWT_SECRET=your-super-secret-jwt-token

# Service URLs (internal)
MODEL_ROUTER_URL=http://model-router:8080
RAG_GATEWAY_URL=http://agent-rag:8501
PUBSUB_EMULATOR_HOST=pubsub-emulator:8085

# API Keys
OPENAI_API_KEY=sk-mock-key-for-development-only
ANTHROPIC_API_KEY=

# Project Settings
ALFRED_PROJECT_ID=alfred-agent-platform
ALFRED_ENVIRONMENT=development
ALFRED_DEBUG=true

# Storage Settings
STORAGE_BACKEND=file
FILE_STORAGE_BACKEND_PATH=/var/lib/storage
```

2. Create an environment variable consistency check script:

```bash
#!/bin/bash
# check-env-consistency.sh

echo "Checking environment variable consistency..."

# Extract all environment variables from docker-compose.yml
grep -o '\${[A-Za-z0-9_]*' docker-compose.unified.yml | sort | uniq | tr -d '${' > all_env_vars.txt

# Compare with .env.example
grep -o '^[A-Za-z0-9_]*=' .env.example | tr -d '=' > env_example_vars.txt

echo "Variables in docker-compose.unified.yml but not in .env.example:"
comm -23 all_env_vars.txt env_example_vars.txt

echo "Variables in .env.example but not used in docker-compose.unified.yml:"
comm -13 all_env_vars.txt env_example_vars.txt

# Cleanup
rm all_env_vars.txt env_example_vars.txt
```

Make the script executable:
```bash
chmod +x check-env-consistency.sh
```

## 5. Error Handling Improvements (OPT-003)

**Impact**: Medium - Improves resilience
**Risk**: Low - Doesn't change core logic

### Implementation

Create a simple utility module for retry logic in `/home/locotoki/projects/alfred-agent-platform-v2/libs/resilience.py`:

```python
"""
Resilience utilities for service interactions.
"""
import asyncio
import functools
import logging
from typing import Callable, TypeVar, Any

T = TypeVar("T")
logger = logging.getLogger(__name__)

def with_retry(
    max_attempts: int = 3,
    initial_backoff: float = 0.5,
    max_backoff: float = 5.0,
    backoff_multiplier: float = 2.0,
    retryable_exceptions: tuple = (Exception,),
):
    """Decorator for functions that should be retried on failure."""
    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @functools.wraps(func)
        async def wrapper(*args: Any, **kwargs: Any) -> T:
            attempt = 0
            current_backoff = initial_backoff
            
            while True:
                attempt += 1
                try:
                    return await func(*args, **kwargs)
                except retryable_exceptions as e:
                    if attempt >= max_attempts:
                        logger.error(
                            f"Failed after {attempt} attempts: {str(e)}"
                        )
                        raise
                    
                    logger.warning(
                        f"Attempt {attempt} failed, retrying in {current_backoff}s: {str(e)}"
                    )
                    await asyncio.sleep(current_backoff)
                    current_backoff = min(
                        current_backoff * backoff_multiplier, max_backoff
                    )
        
        return wrapper
    return decorator
```

Example usage in agent service clients:

```python
# In app/clients/__init__.py or similar

from libs.resilience import with_retry

class ModelClient:
    # ... existing code

    @with_retry(max_attempts=3, retryable_exceptions=(ConnectionError, TimeoutError))
    async def get_completion(self, prompt):
        # Existing code to call model router
        return await self._client.post("/completions", json={"prompt": prompt})
```

## Quick Implementation Checklist

Follow this order for minimal risk:

1. ✅ Environment Variable Cleanup (OPT-005)
   - Create `.env.example`
   - Run consistency check

2. ✅ Error Handling Improvements (OPT-003)
   - Add resilience.py module
   - Update critical client code

3. ✅ Standardize Health Checks (OPT-002)
   - Run standardize-health-checks.sh
   - Verify health checks with docker ps

4. ✅ Startup Sequence Optimization (OPT-004)
   - Update depends_on in docker-compose.unified.yml
   - Test with docker-compose down && docker-compose up -d

5. ✅ Container Resource Limits (OPT-001)
   - Add resource limits
   - Monitor containers for stability
   
Always make one change at a time and test thoroughly before proceeding to the next optimization.
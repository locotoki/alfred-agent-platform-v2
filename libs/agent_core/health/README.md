# Health Check Module

This module provides standardized health check endpoints for services in the Alfred Agent Platform.

## Overview

The health check module implements the three required endpoints as specified in 
`docs/HEALTH_CHECK_STANDARD.md`:

1. `/health` - Detailed health status
2. `/healthz` - Simple health probe 
3. `/metrics` - Prometheus metrics

## Usage

To add standardized health endpoints to your service:

```python
from fastapi import FastAPI
from libs.agent_core.health import create_health_app

# Create your main application
app = FastAPI()

# Add health check endpoints
health_app = create_health_app("service-name", "1.0.0")
app.mount("/health", health_app)

# Your service routes go here
@app.get("/")
async def root():
    return {"message": "Hello World"}
```

## Tracking Dependencies

You can track the health of dependencies with the health app:

```python
# Register dependencies
health_app.register_dependency("database", "ok")
health_app.register_dependency("external-api", "ok")

# Update dependency status when needed
health_app.update_dependency_status("database", "error")
```

The overall service health will be reported as "error" if any dependency has an "error" status.

## Legacy Endpoints

For backward compatibility, the following legacy endpoints are also provided:

- `/` - Basic health check
- `/ready` - Readiness check
- `/live` - Liveness check

These endpoints are maintained for compatibility but may be deprecated in the future.
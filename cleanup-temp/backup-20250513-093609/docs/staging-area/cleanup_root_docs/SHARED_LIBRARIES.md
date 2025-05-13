# Shared Libraries and Stubs

This document provides detailed information about the shared libraries and stub implementations used across the Alfred Agent Platform v2.

## Overview

The platform uses a set of shared libraries for common functionality across services. These libraries are implemented with proper stubs to ensure consistent behavior across environments and for testing.

## Key Shared Libraries

### 1. A2A Adapter Library (`libs/a2a_adapter`)

This library implements the Agent-to-Agent (A2A) communication protocol used throughout the platform.

#### Components:

- **Envelope** (`envelope.py`): Defines the message envelope format
  - `A2AEnvelope`: Main class for standardized message exchange
  - `Artifact`: Class for handling attachments and resources

- **Transport** (`transport.py`): Implements communication channels
  - `PubSubTransport`: Google Pub/Sub implementation
  - `SupabaseTransport`: Supabase/PostgreSQL implementation

- **Middleware** (`middleware.py`): Request/response processing
  - `PolicyMiddleware`: Applies policies like rate limiting and PII scrubbing

#### Recent Improvements:

- Fixed imports of `A2AEnvelope` class in `__init__.py`
- Added missing methods in `PubSubTransport`:
  - `publish_task`: For task envelope publishing
  - Support for topic parameter in publish methods

- Enhanced `SupabaseTransport` with additional methods:
  - `store_task`: Stores task envelopes in database
  - `get_task_status`: Retrieves task status
  - `check_duplicate`: Verifies if a task is a duplicate
  - `update_task_status`: Updates task processing status
  - `store_task_result`: Stores task execution results

### 2. Agent Core Library (`libs/agent_core`)

This library provides core agent functionality shared across all agent services.

#### Components:

- **Base Agent** (`base_agent.py`): Abstract base class for all agents
  - Standardized lifecycle management
  - Task processing framework
  - Status reporting

- **Health** (`health.py`): Health check implementations
  - `create_health_app`: Creates a FastAPI app for health endpoints
  - Standard health check endpoints

#### Recent Improvements:

- Fixed imports of `BaseAgent` class in `__init__.py`
- Simplified `BaseAgent` implementation for better compatibility:
  - Removed direct database access in `_register_agent`
  - Enhanced heartbeat loop to work without database
  - Simplified agent status updates

### 3. Observability Library (`libs/observability`)

This library provides standardized observability tools for all services.

#### Components:

- **Logging** (`logging.py`): Structured logging setup
- **Metrics** (`metrics.py`): Prometheus metrics
- **Tracing** (`tracing.py`): Distributed tracing

## Stub Implementations

The platform uses stub implementations to facilitate development and testing:

### 1. Transport Stubs

```python
# Example PubSubTransport stub
class PubSubTransport:
    def __init__(self, project_id: str):
        self.project_id = project_id
        self.completed_topic_path = "completed-tasks"
        
    async def publish_task(self, envelope: Any, topic: str = None) -> str:
        logger.info("STUB: Publishing task envelope", 
                   intent=getattr(envelope, "intent", "unknown"),
                   topic=topic or "default-topic")
        return "message-id-stub-task"
```

### 2. BaseAgent Stubs

```python
# Example BaseAgent stub implementation
async def _register_agent(self):
    """Register agent in database."""
    # Simplified stub implementation
    logger.info(
        "agent_registered",
        name=self.name,
        type=self.__class__.__name__,
        version=self.version,
        status="active",
        capabilities=self.supported_intents
    )
```

## Best Practices for Library Usage

1. **Consistent Imports**: Always import from the library's `__init__.py`:
   ```python
   from libs.a2a_adapter import A2AEnvelope, PubSubTransport
   ```

2. **Version Checking**: Validate library compatibility:
   ```python
   from libs.agent_core import __version__ as agent_core_version
   assert agent_core_version >= "0.4.0"
   ```

3. **Error Handling**: Always handle potential errors:
   ```python
   try:
       await transport.publish_task(envelope)
   except Exception as e:
       logger.error("Failed to publish task", error=str(e))
   ```

4. **Environment Awareness**: Adapt behavior based on environment:
   ```python
   if os.getenv("ENVIRONMENT") == "development":
       # Use stub implementation
   else:
       # Use real implementation
   ```

## Library Dependencies

The shared libraries have minimal dependencies to ensure wide compatibility:

- **a2a_adapter**: 
  - pydantic
  - asyncio
  - structlog
  - redis (for middleware)

- **agent_core**:
  - pydantic
  - fastapi
  - prometheus-client
  - structlog

- **observability**:
  - structlog
  - prometheus-client
  - opentelemetry-sdk

## Extending Shared Libraries

When extending the shared libraries:

1. **Add classes/methods to the appropriate module**
2. **Update the `__init__.py` to export new classes**
3. **Update stub implementations to match real implementations**
4. **Add tests for new functionality**
5. **Update documentation**

## Common Issues and Solutions

### 1. Missing Imports

**Problem**: `ImportError: cannot import name 'A2AEnvelope' from 'libs.a2a_adapter'`
**Solution**: Ensure the class is exported in `__init__.py`:
```python
from .envelope import A2AEnvelope
__all__ = ["A2AEnvelope"]
```

### 2. Method Not Found

**Problem**: `AttributeError: 'PubSubTransport' object has no attribute 'publish_task'`
**Solution**: Add the missing method to the stub implementation.

### 3. Type Errors

**Problem**: `TypeError: PubSubTransport.subscribe() takes 2 positional arguments but 3 were given`
**Solution**: Update method signatures to match across implementations:
```python
async def subscribe(self, subscription: str, callback: Callable, error_callback: Callable = None):
```

---

*This document is maintained as part of the Alfred Agent Platform v2 project and was last updated on May 6, 2025.*
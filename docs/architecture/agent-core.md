# Agent Core Framework

*Last Updated: 2025-05-10*
*Owner: Architecture Team*
*Status: Active*

## Overview

The Agent Core Framework is the foundational library that standardizes agent development, lifecycle management, and communication in the Alfred Agent Platform v2. It provides a consistent structure and set of abstractions that enable developers to create new agents that seamlessly integrate with the platform while focusing on domain-specific functionality rather than infrastructure concerns.

This framework implements the platform's architectural principles of modularity, scalability, and observability by providing standardized components for event handling, state management, health monitoring, and interoperability. It serves as the foundation for all agents in the platform, ensuring consistency in implementation while allowing for flexibility in agent capabilities.

## Core Principles

The Agent Core Framework is designed around the following principles:

### 1. Separation of Concerns

- **Intent Handling**: Clearly separated from messaging infrastructure
- **State Management**: Abstracted from storage implementation details
- **Business Logic**: Focused on domain functionality without infrastructure code
- **Adapter Pattern**: Clean separation between the agent and external systems

### 2. Configuration over Convention

- **Declarative Intent Mapping**: Intent handlers registered declaratively
- **Configuration-Driven**: Behavior configured rather than coded
- **Pluggable Components**: Standardized component interfaces for customization
- **Environment Awareness**: Automatic adaptation to different environments

### 3. Observability by Default

- **Built-in Metrics**: Standard performance and health metrics
- **Structured Logging**: Consistent logging format with contextual information
- **Distributed Tracing**: Automatic trace propagation across component boundaries
- **Health Reporting**: Standardized health check mechanism

### 4. Robustness

- **Error Handling**: Comprehensive error handling and recovery
- **Retry Policies**: Configurable retry behavior for transient failures
- **Circuit Breaking**: Protection against cascading failures
- **Graceful Degradation**: Ability to operate with reduced functionality

## Framework Architecture

The Agent Core Framework is organized into the following main components:

```
┌───────────────────────────────────────────────────────────┐
│                    Agent Core Framework                    │
│                                                           │
│  ┌─────────────────┐      ┌─────────────────────────────┐ │
│  │ Agent Lifecycle │      │ Configuration Management    │ │
│  └─────────────────┘      └─────────────────────────────┘ │
│                                                           │
│  ┌─────────────────┐      ┌─────────────────────────────┐ │
│  │ Intent Handling │      │ State Management            │ │
│  └─────────────────┘      └─────────────────────────────┘ │
│                                                           │
│  ┌─────────────────┐      ┌─────────────────────────────┐ │
│  │ Messaging       │      │ Monitoring & Observability  │ │
│  └─────────────────┘      └─────────────────────────────┘ │
│                                                           │
│  ┌─────────────────┐      ┌─────────────────────────────┐ │
│  │ Security        │      │ External Adapters           │ │
│  └─────────────────┘      └─────────────────────────────┘ │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

### Agent Lifecycle

Manages the agent's lifecycle phases including:

- **Initialization**: Configuration loading and component setup
- **Registration**: Self-registration with the agent registry
- **Operation**: Normal operation with task processing
- **Maintenance**: Periodic maintenance operations
- **Shutdown**: Graceful shutdown and resource cleanup

### Configuration Management

Handles agent configuration:

- **Config Loading**: Multiple sources (files, environment, service registry)
- **Validation**: Schema-based configuration validation
- **Secrets Management**: Secure handling of sensitive configuration
- **Dynamic Updates**: Runtime configuration updates when supported

### Intent Handling

Provides the core functionality for processing agent intents:

- **Intent Registry**: Registration and discovery of supported intents
- **Handler Mapping**: Routing from intent to appropriate handler
- **Parameter Validation**: Validation of request parameters
- **Execution Context**: Contextual information for request processing
- **Result Formatting**: Standardized result formatting

### State Management

Manages persistent state for the agent:

- **State Repository**: Abstract interface to state storage
- **Transactional Updates**: Atomic state operations
- **Caching**: Performance optimization for state access
- **Synchronization**: Consistency mechanisms for distributed state
- **Versioning**: State versioning for conflict resolution

### Messaging

Implements A2A protocol communication:

- **Message Serialization**: Converting objects to A2A protocol format
- **Transport Adapters**: Support for different transport mechanisms
- **Delivery Guarantees**: Implementation of exactly-once processing
- **Message Routing**: Intelligent routing to appropriate destinations
- **Backpressure Handling**: Protection against message overload

### Monitoring & Observability

Provides built-in monitoring capabilities:

- **Metrics Collection**: Standard and custom metric collection
- **Health Checks**: Active and passive health monitoring
- **Logging**: Structured, contextual logging
- **Tracing**: Distributed tracing integration
- **Alerting**: Threshold-based alerting integration

### Security

Implements security mechanisms:

- **Authentication**: Verifying identity of message senders
- **Authorization**: Enforcing access control policies
- **Encryption**: Protecting sensitive payloads
- **Audit Logging**: Recording security-relevant events
- **Threat Protection**: Defense against common attack vectors

### External Adapters

Provides standardized interfaces to external systems:

- **LLM Adapters**: Integration with language models
- **Database Adapters**: Connections to database systems
- **API Adapters**: Integration with external APIs
- **Storage Adapters**: Access to file storage systems
- **Vector DB Adapters**: Integration with vector databases

## Implementation Details

### Core Classes and Interfaces

#### `Agent` Class

The primary class that encapsulates agent functionality:

```python
class Agent:
    """Base class for all agents in the platform."""

    def __init__(self, config: AgentConfig):
        """Initialize agent with configuration."""
        self.config = config
        self.state_manager = StateManagerFactory.create(config.state)
        self.intent_registry = IntentRegistry()
        self.messaging = MessagingFactory.create(config.messaging)
        self.monitor = MonitoringFactory.create(config.monitoring)
        self.security = SecurityFactory.create(config.security)
        self._register_default_intents()

    def register_intent(self, intent: str, handler: Callable):
        """Register a handler for a specific intent."""
        self.intent_registry.register(intent, handler)

    async def handle_task(self, task: Task) -> TaskResult:
        """Process an incoming task based on its intent."""
        intent = task.message.intent
        handler = self.intent_registry.get_handler(intent)

        if not handler:
            raise IntentNotSupportedError(f"Intent {intent} not supported")

        with self.monitor.measure_execution_time(intent):
            try:
                result = await handler(task)
                return result
            except Exception as e:
                self.monitor.record_error(intent, e)
                raise

    async def start(self):
        """Start the agent and begin processing tasks."""
        await self._register_with_registry()
        await self.messaging.start_listening(self._message_handler)
        await self.monitor.start_reporting()
        self.monitor.record_agent_started()

    async def stop(self):
        """Stop the agent gracefully."""
        await self.messaging.stop_listening()
        await self.monitor.stop_reporting()
        self.monitor.record_agent_stopped()
```

#### `IntentRegistry` Class

Manages the registration and retrieval of intent handlers:

```python
class IntentRegistry:
    """Registry for intent handlers."""

    def __init__(self):
        self._handlers = {}

    def register(self, intent: str, handler: Callable):
        """Register a handler for an intent."""
        self._handlers[intent] = handler

    def get_handler(self, intent: str) -> Optional[Callable]:
        """Get the handler for an intent."""
        return self._handlers.get(intent)

    def list_intents(self) -> List[str]:
        """List all registered intents."""
        return list(self._handlers.keys())
```

#### `StateManager` Interface

Abstract interface for state management:

```python
class StateManager(ABC):
    """Abstract interface for agent state management."""

    @abstractmethod
    async def get(self, key: str) -> Any:
        """Get a state value by key."""
        pass

    @abstractmethod
    async def set(self, key: str, value: Any) -> None:
        """Set a state value by key."""
        pass

    @abstractmethod
    async def delete(self, key: str) -> None:
        """Delete a state value by key."""
        pass

    @abstractmethod
    async def transaction(self, operations: List[StateOperation]) -> None:
        """Execute multiple operations in a transaction."""
        pass
```

#### `Messaging` Interface

Abstract interface for messaging:

```python
class Messaging(ABC):
    """Abstract interface for agent messaging."""

    @abstractmethod
    async def send(self, message: Message, topic: str) -> str:
        """Send a message to a topic."""
        pass

    @abstractmethod
    async def start_listening(self, handler: Callable[[Message], Awaitable[None]]) -> None:
        """Start listening for messages."""
        pass

    @abstractmethod
    async def stop_listening(self) -> None:
        """Stop listening for messages."""
        pass
```

### Configuration Structure

Agent configuration follows a standardized structure:

```yaml
agent:
  id: "example-agent"
  name: "Example Agent"
  version: "1.0.0"
  description: "An example agent implementation"

intents:
  - name: "EXAMPLE_TASK"
    description: "Handles example tasks"
    parameters:
      - name: "param1"
        type: "string"
        required: true
      - name: "param2"
        type: "integer"
        required: false

state:
  provider: "supabase"
  table: "agent_state"

messaging:
  primary:
    provider: "pubsub"
    topic_prefix: "a2a"
  fallback:
    provider: "supabase_realtime"
    channel_prefix: "a2a"

security:
  authentication:
    provider: "jwt"
  authorization:
    provider: "rbac"

monitoring:
  metrics:
    provider: "prometheus"
  tracing:
    provider: "opentelemetry"
  logging:
    provider: "structured_json"
    level: "info"
```

## Usage Patterns

### Basic Agent Implementation

Implementing a new agent using the Agent Core Framework:

```python
from agent_core import Agent, AgentConfig, Task, TaskResult

class MyCustomAgent(Agent):
    """Custom agent implementation."""

    def __init__(self, config: AgentConfig):
        super().__init__(config)
        # Register intent handlers
        self.register_intent("CUSTOM_INTENT", self.handle_custom_intent)

    async def handle_custom_intent(self, task: Task) -> TaskResult:
        """Handler for CUSTOM_INTENT."""
        # Extract parameters from task
        param1 = task.message.payload.get("param1")

        # Custom business logic
        result_data = await self._process_custom_logic(param1)

        # Return structured result
        return TaskResult(
            status="SUCCESS",
            data=result_data,
            metadata={"processing_time": "1.5s"}
        )

    async def _process_custom_logic(self, param1: str) -> dict:
        """Internal method for custom business logic."""
        # Custom implementation...
        return {"result": f"Processed {param1}"}
```

### Agent Startup Pattern

Pattern for starting an agent in a service:

```python
import asyncio
import os
import yaml
from my_custom_agent import MyCustomAgent
from agent_core import AgentConfig

async def main():
    # Load configuration
    config_path = os.environ.get("CONFIG_PATH", "config.yaml")
    with open(config_path) as f:
        config_data = yaml.safe_load(f)

    # Create agent configuration
    config = AgentConfig.from_dict(config_data)

    # Create and start agent
    agent = MyCustomAgent(config)

    try:
        # Start the agent
        await agent.start()

        # Keep running until interrupted
        while True:
            await asyncio.sleep(1)
    except KeyboardInterrupt:
        # Graceful shutdown
        await agent.stop()

if __name__ == "__main__":
    asyncio.run(main())
```

### State Management Pattern

Pattern for managing agent state:

```python
class UserProfileAgent(Agent):
    """Agent for managing user profiles."""

    async def handle_update_profile(self, task: Task) -> TaskResult:
        """Handle profile update."""
        user_id = task.message.payload.get("user_id")
        profile_data = task.message.payload.get("profile_data")

        # Get current profile
        current_profile = await self.state_manager.get(f"profile:{user_id}")

        if not current_profile:
            current_profile = {"user_id": user_id, "created_at": datetime.now().isoformat()}

        # Update profile with new data
        updated_profile = {**current_profile, **profile_data, "updated_at": datetime.now().isoformat()}

        # Save updated profile
        await self.state_manager.set(f"profile:{user_id}", updated_profile)

        return TaskResult(
            status="SUCCESS",
            data={"profile_id": user_id}
        )
```

### LLM Integration Pattern

Pattern for integrating with language models:

```python
from agent_core import Agent, Task, TaskResult
from agent_core.adapters import LLMAdapter

class ContentGenerationAgent(Agent):
    """Agent for generating content using LLMs."""

    def __init__(self, config):
        super().__init__(config)
        self.llm_adapter = LLMAdapter.create(config.llm)

    async def handle_generate_content(self, task: Task) -> TaskResult:
        """Handle content generation."""
        content_type = task.message.payload.get("content_type")
        prompt = task.message.payload.get("prompt")

        # Generate content using LLM
        generated_content = await self.llm_adapter.generate(
            prompt=prompt,
            max_tokens=1500,
            temperature=0.7
        )

        # Save to state if needed
        content_id = str(uuid.uuid4())
        await self.state_manager.set(f"content:{content_id}", {
            "id": content_id,
            "type": content_type,
            "prompt": prompt,
            "content": generated_content,
            "created_at": datetime.now().isoformat()
        })

        return TaskResult(
            status="SUCCESS",
            data={
                "content_id": content_id,
                "content": generated_content
            }
        )
```

## Adapters

The Agent Core Framework provides a set of adapters for integrating with various external systems.

### Standard Adapters

#### LLM Adapters

Integrates with various language model providers:

- **OpenAI Adapter**: Integration with OpenAI models
- **Anthropic Adapter**: Integration with Claude models
- **Ollama Adapter**: Integration with locally-hosted models
- **HuggingFace Adapter**: Integration with HuggingFace models

#### Database Adapters

Provides standardized database connectivity:

- **Supabase Adapter**: Integration with Supabase PostgreSQL
- **Firestore Adapter**: Legacy support for Firestore
- **Redis Adapter**: Integration with Redis for caching

#### Vector Database Adapters

Specialized adapters for vector operations:

- **Qdrant Adapter**: Integration with Qdrant vector database
- **PGVector Adapter**: Integration with PostgreSQL pgvector extension
- **Redis Vector Adapter**: Integration with Redis for vector operations

#### Storage Adapters

File storage integration:

- **Supabase Storage Adapter**: Integration with Supabase Storage
- **Cloud Storage Adapter**: Integration with cloud storage providers
- **Local Storage Adapter**: Integration with local filesystem

#### API Adapters

Integration with external APIs:

- **REST Adapter**: Integration with RESTful APIs
- **GraphQL Adapter**: Integration with GraphQL APIs
- **SOAP Adapter**: Integration with legacy SOAP services

### Implementing Custom Adapters

The framework supports creating custom adapters by implementing the appropriate interface:

```python
from agent_core.adapters import LLMAdapter, LLMResponse

class CustomLLMAdapter(LLMAdapter):
    """Custom LLM adapter implementation."""

    def __init__(self, config):
        super().__init__(config)
        # Custom initialization
        self.api_key = config.get("api_key")
        self.base_url = config.get("base_url")
        # Initialize client
        self.client = CustomLLMClient(self.api_key, self.base_url)

    async def generate(self, prompt: str, **params) -> LLMResponse:
        """Generate text using the custom LLM."""
        # Call the custom LLM service
        response = await self.client.generate(
            prompt=prompt,
            max_tokens=params.get("max_tokens", 1000),
            temperature=params.get("temperature", 0.7)
        )

        # Convert to standard response format
        return LLMResponse(
            text=response.text,
            usage={
                "prompt_tokens": response.usage.prompt_tokens,
                "completion_tokens": response.usage.completion_tokens,
                "total_tokens": response.usage.total_tokens
            },
            model=response.model,
            metadata=response.metadata
        )
```

## Monitoring and Observability

The framework provides comprehensive monitoring capabilities out of the box.

### Metrics

Standard metrics collected for all agents:

| Metric | Type | Description |
|--------|------|-------------|
| agent_tasks_received_total | Counter | Total number of tasks received |
| agent_tasks_completed_total | Counter | Total number of completed tasks |
| agent_tasks_failed_total | Counter | Total number of failed tasks |
| agent_task_duration_seconds | Histogram | Task processing duration |
| agent_state_operations_total | Counter | Total number of state operations |
| agent_state_operation_duration_seconds | Histogram | State operation duration |
| agent_message_sent_total | Counter | Total number of messages sent |
| agent_message_received_total | Counter | Total number of messages received |

### Health Checks

Built-in health checks:

- **Liveness**: Confirms the agent process is running
- **Readiness**: Confirms the agent is ready to process tasks
- **Dependency**: Checks the health of dependencies (database, messaging, etc.)
- **State**: Verifies state storage is functioning properly

### Logging

Structured logging with standard fields:

```json
{
  "timestamp": "2025-05-10T12:34:56.789Z",
  "level": "info",
  "agent_id": "example-agent",
  "service_id": "example-service",
  "trace_id": "abcdef123456",
  "correlation_id": "fedcba654321",
  "intent": "EXAMPLE_INTENT",
  "message": "Processing task example",
  "context": {
    "user_id": "user123",
    "task_id": "task456"
  }
}
```

### Tracing

Distributed tracing integration:

- **Trace Propagation**: Automatic propagation of trace context
- **Span Creation**: Spans for key operations (task handling, state access, etc.)
- **Attribute Attachment**: Standard and custom attributes on spans
- **Sampling**: Configurable sampling based on intent or other criteria

## Best Practices

### Agent Design

- **Single Responsibility**: Design agents with clear, focused responsibilities
- **Stateless Processing**: Minimize internal state, use state manager for persistence
- **Idempotent Operations**: Design handlers to be safely retryable
- **Graceful Degradation**: Handle dependency failures gracefully
- **Clear Intent Definition**: Define intents with clear boundaries and parameters

### Error Handling

- **Structured Errors**: Use the framework's error hierarchy for clear categorization
- **Detailed Context**: Include relevant context in error messages
- **Graceful Recovery**: Implement recovery mechanisms for transient failures
- **Circuit Breaking**: Use circuit breakers for external dependencies
- **Monitoring**: Ensure errors are properly logged and monitored

### State Management

- **Minimal State**: Store only essential data in agent state
- **Transactional Updates**: Use transactions for related state changes
- **State Versioning**: Include version information in state data
- **Cleanup Policies**: Implement TTL or cleanup for temporary state
- **Caching Strategy**: Use appropriate caching for frequent state access

### Performance Optimization

- **Asynchronous Processing**: Use asynchronous patterns throughout
- **Batching**: Batch related operations when possible
- **Connection Pooling**: Use connection pools for database access
- **Resource Limits**: Configure appropriate resource limits
- **Caching**: Implement strategic caching for frequent operations

## Troubleshooting

### Common Issues

| Issue | Possible Causes | Resolution |
|-------|----------------|------------|
| Agent fails to start | Configuration errors, missing dependencies | Check configuration, verify all dependencies are available |
| Task handling timeouts | Long-running operations, external service delays | Implement timeouts, use asynchronous patterns, optimize processing |
| State access errors | Database connectivity issues, permission problems | Check connection strings, verify permissions, check database status |
| Message delivery failures | Messaging service issues, topic/subscription problems | Verify messaging service health, check topic/subscription configuration |
| High task failure rate | Handler errors, invalid inputs, dependency issues | Review error logs, validate input schemas, check dependencies |

### Debugging Tools

- **Agent Shell**: Interactive debugging shell for agent operations
- **Trace Viewer**: Web interface for examining distributed traces
- **Metrics Dashboard**: Grafana dashboard for agent metrics
- **Log Explorer**: Structured log search and filtering
- **State Explorer**: Tool for exploring agent state data

## Deployment

### Environment Configuration

Agents can be configured for different environments:

```yaml
development:
  state:
    provider: "local"
  messaging:
    provider: "pubsub_emulator"

testing:
  state:
    provider: "in_memory"
  messaging:
    provider: "in_memory"

production:
  state:
    provider: "supabase"
    connection_string: "${SUPABASE_URL}"
    credentials: "${SUPABASE_KEY}"
  messaging:
    provider: "pubsub"
    project_id: "${GCP_PROJECT_ID}"
```

### Container Deployment

Agents are typically deployed as containers:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "main.py"]
```

### Resource Requirements

Typical resource requirements for agent containers:

| Resource | Development | Production (Base) | Production (High Load) |
|----------|-------------|------------------|------------------------|
| CPU | 0.5 cores | 1-2 cores | 4-8 cores |
| Memory | 512MB | 1-2GB | 4-8GB |
| Disk | 1GB | 10GB | 20GB+ |

### Scaling Considerations

Agents can be scaled horizontally:

- **Instance Count**: Multiple instances of the same agent for load distribution
- **Resource Allocation**: Appropriate CPU and memory allocation per instance
- **Auto-scaling**: Scaling based on task queue length or resource utilization
- **Specialization**: Specialized instances for specific intents

## Related Documentation

- [System Architecture](../architecture/system-architecture.md)
- [A2A Protocol Documentation](../api/a2a-protocol.md)
- [Agent Implementation Guide](../agents/guides/agent-implementation-guide.md)
- [State Storage Configuration](../operations/state-storage-configuration.md)
- [Messaging Configuration](../operations/pubsub-configuration.md)
- [Monitoring Setup](../operations/monitoring-setup.md)

## References

- [Python AsyncIO Documentation](https://docs.python.org/3/library/asyncio.html)
- [LangChain Documentation](https://python.langchain.com/docs/get_started/introduction)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- [Supabase Python Client](https://supabase.com/docs/reference/python/introduction)

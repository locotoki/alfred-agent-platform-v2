# Agent Implementation Guide - AI Agent Platform v2

## Introduction

This guide provides comprehensive instructions for developing and deploying new agents within the AI Agent Platform v2. The platform is built on a modular, event-driven architecture that leverages Supabase for state storage and Pub/Sub for inter-agent communication. This document serves as the definitive resource for developers implementing new agents in the platform.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Agent Implementation Steps](#agent-implementation-steps)
3. [A2A Communication Protocol](#a2a-communication-protocol)
4. [Supabase Integration](#supabase-integration)
5. [Pub/Sub Integration](#pubsub-integration)
6. [LangChain and LangGraph Implementation](#langchain-and-langgraph-implementation)
7. [Testing Your Agent](#testing-your-agent)
8. [Monitoring and Observability](#monitoring-and-observability)
9. [Error Handling and Resilience](#error-handling-and-resilience)
10. [State Management](#state-management)
11. [Documentation Requirements](#documentation-requirements)
12. [Agent Deployment Checklist](#agent-deployment-checklist)
13. [Troubleshooting](#troubleshooting)

## Architecture Overview

The AI Agent Platform v2 follows these key design principles:

- **Scalability**: Horizontal scaling across multiple containers or nodes
- **Modularity**: Loose coupling between components using standardized envelopes (A2A schema)
- **Flexibility & Extensibility**: Open standards and pluggable agents
- **Security & Privacy**: Role-based access control and data encryption
- **Observability & Monitoring**: End-to-end tracing and comprehensive metrics

Core components include:

- **Transport Layer**: Google Cloud Pub/Sub for inter-agent communication
- **State Storage**: Supabase (PostgreSQL with pgvector) for structured data and vector storage
- **Vector Storage**: Qdrant for optimized vector searches
- **AI Agent Framework**: LangChain for orchestration and LangGraph for complex workflows
- **Observability**: LangSmith, Prometheus, Grafana, and OpenTelemetry

## Agent Implementation Steps

### 1. Set Up Your Development Environment

```bash
# Clone the repository (if not already done)
git clone https://github.com/your-org/alfred-agent-platform-v2.git
cd alfred-agent-platform-v2

# Install dependencies
pip install -r requirements.txt
```

### 2. Create Your Agent Directory Structure

```bash
# Create your agent directory structure
mkdir -p agents/your_agent_name/{__pycache__,tests}
touch agents/your_agent_name/__init__.py
touch agents/your_agent_name/agent.py
touch agents/your_agent_name/models.py
touch agents/your_agent_name/chains.py
touch agents/your_agent_name/tests/__init__.py
touch agents/your_agent_name/tests/test_agent.py
touch agents/your_agent_name/tests/test_models.py
touch agents/your_agent_name/tests/test_chains.py
```

### 3. Implement Core Agent Classes

#### 3.1 Agent Implementation (agent.py)

```python
"""Your agent name implementation"""

from typing import Dict, Any, List
import structlog
from langchain_openai import ChatOpenAI
from langgraph.graph import Graph, END

from libs.agent_core import BaseAgent
from libs.a2a_adapter import A2AEnvelope
from .chains import YourCustomChain1, YourCustomChain2
from .models import YourRequestModel1, YourResponseModel1

logger = structlog.get_logger(__name__)

class YourAgentName(BaseAgent):
    """Agent for your specific domain tasks"""

    def __init__(self, *args, **kwargs):
        super().__init__(
            name="your-agent-name",
            version="1.0.0",
            supported_intents=[
                "YOUR_INTENT_1",
                "YOUR_INTENT_2",
                # Add more intents as needed
            ],
            *args,
            **kwargs
        )
        self.setup_chains()
        self.setup_graph()

    def setup_chains(self):
        """Initialize LangChain configurations for each intent"""
        llm = ChatOpenAI(temperature=0, model="gpt-4")

        self.custom_chain_1 = YourCustomChain1(llm)
        self.custom_chain_2 = YourCustomChain2(llm)

    def setup_graph(self):
        """Setup LangGraph for workflow orchestration"""
        self.workflow_graph = Graph()

        # Add nodes for different processing steps
        self.workflow_graph.add_node("parse_request", self._parse_request)
        self.workflow_graph.add_node("validate_data", self._validate_data)
        self.workflow_graph.add_node("process_intent_1", self._process_intent_1)
        self.workflow_graph.add_node("process_intent_2", self._process_intent_2)
        self.workflow_graph.add_node("format_response", self._format_response)

        # Add edges for workflow
        self.workflow_graph.add_edge("parse_request", "validate_data")

        # Add conditional edges based on intent
        self.workflow_graph.add_conditional_edges(
            "validate_data",
            self._route_by_intent,
            {
                "intent_1": "process_intent_1",
                "intent_2": "process_intent_2",
            }
        )

        # All processing nodes lead to format_response
        self.workflow_graph.add_edge("process_intent_1", "format_response")
        self.workflow_graph.add_edge("process_intent_2", "format_response")

        # format_response leads to END
        self.workflow_graph.add_edge("format_response", END)

        # Set entry point
        self.workflow_graph.set_entry_point("parse_request")

        # Compile the graph
        self.workflow = self.workflow_graph.compile()

    async def process_task(self, envelope: A2AEnvelope) -> Dict[str, Any]:
        """Process a task"""
        logger.info(
            "processing_task",
            task_id=envelope.task_id,
            intent=envelope.intent
        )

        try:
            # Execute the workflow
            result = await self.workflow.ainvoke({
                "envelope": envelope,
                "intent": envelope.intent,
                "content": envelope.content
            })

            return result.get("response", {})

        except Exception as e:
            logger.error(
                "task_processing_failed",
                error=str(e),
                task_id=envelope.task_id,
                intent=envelope.intent
            )
            raise

    # Workflow node implementations
    async def _parse_request(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """Parse the incoming request"""
        state["parsed_content"] = state["content"]
        return state

    async def _validate_data(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """Validate the request data"""
        # Add validation logic here
        state["is_valid"] = True
        return state

    def _route_by_intent(self, state: Dict[str, Any]) -> str:
        """Route to appropriate processor based on intent"""
        intent = state["intent"]
        if intent == "YOUR_INTENT_1":
            return "intent_1"
        elif intent == "YOUR_INTENT_2":
            return "intent_2"
        else:
            raise ValueError(f"Unsupported intent: {intent}")

    async def _process_intent_1(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """Process intent 1 request"""
        request = YourRequestModel1(**state["parsed_content"])
        result = await self.custom_chain_1.process(request)
        state["result"] = result.dict()
        return state

    async def _process_intent_2(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """Process intent 2 request"""
        # Process intent 2 similarly
        # ...
        return state

    async def _format_response(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """Format the response for output"""
        state["response"] = {
            "status": "success",
            "intent": state["intent"],
            "result": state["result"]
        }
        return state
```

#### 3.2 Data Models (models.py)

```python
"""Data models for your agent"""

from enum import Enum
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field

class SomeEnum(str, Enum):
    OPTION_A = "option_a"
    OPTION_B = "option_b"
    OPTION_C = "option_c"

class YourRequestModel1(BaseModel):
    """Model for your first request type"""
    field1: str
    field2: int
    option: SomeEnum
    metadata: Dict[str, Any] = Field(default_factory=dict)

class YourResponseModel1(BaseModel):
    """Model for your first response type"""
    result_field1: str
    result_field2: float
    status: str
    details: List[Dict[str, Any]] = Field(default_factory=list)
    timestamp: str

# Add more models as needed
```

#### 3.3 LangChain Implementation (chains.py)

```python
"""LangChain implementations for your agent"""

from typing import Dict, Any, List
from langchain.chains import LLMChain
from langchain.prompts import PromptTemplate
from langchain_openai import ChatOpenAI
from langchain.output_parsers import PydanticOutputParser
from .models import YourRequestModel1, YourResponseModel1

class YourCustomChain1:
    """Chain for processing your first intent"""

    def __init__(self, llm: ChatOpenAI = None):
        self.llm = llm or ChatOpenAI(temperature=0, model="gpt-4")
        self.output_parser = PydanticOutputParser(pydantic_object=YourResponseModel1)

        self.prompt = PromptTemplate(
            template="""You are an expert in [your domain]. Process the following information:

Field1: {field1}
Field2: {field2}
Option: {option}
Additional Data: {metadata}

Provide a detailed response including:
1. First result
2. Second result
3. Details
4. Status assessment

{format_instructions}
""",
            input_variables=["field1", "field2", "option", "metadata"],
            partial_variables={"format_instructions": self.output_parser.get_format_instructions()}
        )

        self.chain = LLMChain(llm=self.llm, prompt=self.prompt)

    async def process(self, request: YourRequestModel1) -> YourResponseModel1:
        """Process request"""
        result = await self.chain.arun(
            field1=request.field1,
            field2=request.field2,
            option=request.option.value,
            metadata=request.metadata
        )

        return self.output_parser.parse(result)

# Add more chains as needed
```

## A2A Communication Protocol

The AI Agent Platform v2 uses a standardized Agent-to-Agent (A2A) protocol for communication. This protocol is implemented through envelope schemas that ensure consistent messaging between agents.

### A2A Envelope Schema

The envelope schema is defined in `libs/a2a_adapter/envelope.py` and includes:

```python
class A2AEnvelope(BaseModel):
    schema_version: str = "0.4"
    task_id: str = Field(default_factory=lambda: str(uuid4()))
    intent: str
    role: str = "assistant"
    content: Dict[str, Any] = Field(default_factory=dict)
    artifacts: List[Artifact] = Field(default_factory=list)
    trace_id: str = Field(default_factory=lambda: str(uuid4()))
    correlation_id: Optional[str] = None
    timestamp: str = Field(default_factory=lambda: datetime.utcnow().isoformat() + "Z")
    metadata: Dict[str, Any] = Field(default_factory=dict)
    priority: int = Field(default=1, ge=1, le=5)
    timeout_seconds: int = Field(default=300, ge=1, le=3600)
```

### Key Fields:

- **schema_version**: Version of the A2A envelope schema
- **task_id**: Unique identifier for the task
- **intent**: The purpose or action requested (e.g., "TAX_CALCULATION")
- **content**: The payload containing task data
- **artifacts**: Any files or data artifacts associated with the task
- **trace_id**: For distributed tracing and debugging
- **correlation_id**: Links related tasks together
- **timestamp**: When the envelope was created
- **metadata**: Additional contextual information
- **priority**: Task priority (1-5, with 1 being highest)
- **timeout_seconds**: How long the task should be allowed to run

### Creating an A2A Envelope

```python
from libs.a2a_adapter import A2AEnvelope

# Create a new envelope
envelope = A2AEnvelope(
    intent="YOUR_INTENT",
    content={
        "field1": "value1",
        "field2": 42,
        "option": "option_a"
    },
    metadata={
        "source": "your-agent",
        "environment": "production"
    }
)
```

### Converting to/from Pub/Sub Messages

```python
# Convert to Pub/Sub message
pubsub_message = envelope.to_pubsub_message()

# Parse from Pub/Sub message
parsed_envelope = A2AEnvelope.from_pubsub_message(pubsub_message)
```

## Supabase Integration

Supabase serves as the primary state storage for the platform, replacing Firestore from version 1.

### Key Tables

1. **agent_registry**: Stores information about available agents
2. **tasks**: Stores task information and status
3. **task_results**: Stores task results
4. **agent_health**: Stores agent health information

### Agent Registration

Agents register with the platform during startup by adding their information to the `agent_registry` table:

```python
async def _register_agent(self):
    """Register agent in database."""
    agent_data = {
        "name": self.name,
        "version": self.version,
        "type": self.__class__.__name__,
        "status": "active",
        "capabilities": self.supported_intents,
        "last_heartbeat": datetime.utcnow().isoformat() + "Z"
    }

    await self.supabase.execute(
        """
        INSERT INTO agent_registry (name, version, type, status, capabilities, last_heartbeat)
        VALUES (:name, :version, :type, :status, :capabilities, :last_heartbeat)
        ON CONFLICT (name) DO UPDATE SET
            version = :version,
            status = :status,
            capabilities = :capabilities,
            last_heartbeat = :last_heartbeat
        """,
        agent_data
    )
```

### Task Storage

Store task information and update status:

```python
async def store_task(self, envelope):
    """Store task in database."""
    task_data = {
        "task_id": envelope.task_id,
        "intent": envelope.intent,
        "status": "pending",
        "content": json.dumps(envelope.content),
        "trace_id": envelope.trace_id,
        "correlation_id": envelope.correlation_id,
        "priority": envelope.priority,
        "created_at": envelope.timestamp
    }

    await self.execute(
        """
        INSERT INTO tasks (task_id, intent, status, content, trace_id,
                          correlation_id, priority, created_at)
        VALUES (:task_id, :intent, :status, :content, :trace_id,
                :correlation_id, :priority, :created_at)
        """,
        task_data
    )
```

### State Management

For complex state that requires vector capabilities, use pgvector:

```python
async def store_embedding(self, task_id, embedding, metadata):
    """Store embedding in database."""
    data = {
        "task_id": task_id,
        "embedding": embedding,
        "metadata": json.dumps(metadata)
    }

    await self.execute(
        """
        INSERT INTO embeddings (task_id, embedding, metadata)
        VALUES (:task_id, :embedding, :metadata)
        """,
        data
    )
```

## Pub/Sub Integration

Google Cloud Pub/Sub is used for inter-agent communication, providing exactly-once semantics.

### Key Topics

1. **a2a.tasks.create**: For task initiation
2. **a2a.tasks.completed**: For task completion

### Publishing Tasks

```python
async def publish_task(self, envelope, topic=None):
    """Publish task to Pub/Sub."""
    topic_path = topic or self.create_topic_path
    message = envelope.to_pubsub_message()

    message_id = await self.publish(
        topic_path,
        message["data"].encode("utf-8"),
        message["attributes"]
    )

    return message_id
```

### Subscribing to Tasks

```python
async def subscribe(self, subscription, callback, error_callback=None):
    """Subscribe to Pub/Sub topic."""
    subscription_path = self.client.subscription_path(
        self.project_id, subscription
    )

    # Create subscription if it doesn't exist
    if not self.subscription_exists(subscription):
        self.create_subscription(subscription, self.create_topic_path)

    async def process_message(message):
        try:
            envelope = A2AEnvelope.from_pubsub_message({
                "data": message.data,
                "attributes": message.attributes
            })

            await callback(envelope)
            message.ack()

        except Exception as e:
            if error_callback:
                await error_callback(e)
            message.nack()

    # Create subscriber
    subscriber = self.client.subscribe(
        subscription_path,
        process_message
    )

    return subscriber
```

## LangChain and LangGraph Implementation

The platform leverages LangChain for orchestrating task workflows and LangGraph for complex decision-making and workflows.

### Setting Up LangChain Chains

```python
from langchain.chains import LLMChain
from langchain.prompts import PromptTemplate
from langchain_openai import ChatOpenAI
from langchain.output_parsers import PydanticOutputParser

# Create output parser for structured output
output_parser = PydanticOutputParser(pydantic_object=YourResponseModel)

# Create prompt template
prompt = PromptTemplate(
    template="""You are an expert in [your domain]. Process the following information:

Field1: {field1}
Field2: {field2}
Option: {option}
Additional Data: {metadata}

Provide a detailed response including:
1. First result
2. Second result
3. Details
4. Status assessment

{format_instructions}
""",
    input_variables=["field1", "field2", "option", "metadata"],
    partial_variables={"format_instructions": output_parser.get_format_instructions()}
)

# Create chain
llm = ChatOpenAI(temperature=0, model="gpt-4")
chain = LLMChain(llm=llm, prompt=prompt)

# Use the chain
result = await chain.arun(
    field1="value1",
    field2=42,
    option="option_a",
    metadata={"key": "value"}
)

# Parse the result
parsed_result = output_parser.parse(result)
```

### Setting Up LangGraph Workflows

```python
from langgraph.graph import Graph, END

# Create graph
workflow_graph = Graph()

# Add nodes
workflow_graph.add_node("parse_request", parse_request_function)
workflow_graph.add_node("validate_data", validate_data_function)
workflow_graph.add_node("process_data", process_data_function)
workflow_graph.add_node("format_response", format_response_function)

# Add edges
workflow_graph.add_edge("parse_request", "validate_data")
workflow_graph.add_edge("validate_data", "process_data")
workflow_graph.add_edge("process_data", "format_response")
workflow_graph.add_edge("format_response", END)

# Add conditional routing
workflow_graph.add_conditional_edges(
    "validate_data",
    routing_function,
    {
        "valid": "process_data",
        "invalid": "format_response"
    }
)

# Set entry point
workflow_graph.set_entry_point("parse_request")

# Compile graph
workflow = workflow_graph.compile()

# Execute workflow
result = await workflow.ainvoke({
    "input_data": your_input_data
})
```

## Testing Your Agent

### Unit Testing

```python
import pytest
import asyncio
from unittest.mock import MagicMock, patch
from libs.a2a_adapter import A2AEnvelope
from your_agent.agent import YourAgentName

@pytest.fixture
def mock_pubsub():
    return MagicMock()

@pytest.fixture
def mock_supabase():
    return MagicMock()

@pytest.fixture
def mock_policy():
    return MagicMock()

@pytest.fixture
def agent(mock_pubsub, mock_supabase, mock_policy):
    return YourAgentName(
        pubsub_transport=mock_pubsub,
        supabase_transport=mock_supabase,
        policy_middleware=mock_policy
    )

@pytest.mark.asyncio
async def test_process_task(agent):
    # Create test envelope
    envelope = A2AEnvelope(
        intent="YOUR_INTENT_1",
        content={
            "field1": "test value",
            "field2": 42,
            "option": "option_a"
        }
    )

    # Mock chain response
    with patch.object(agent.custom_chain_1, 'process') as mock_process:
        mock_process.return_value = YourResponseModel1(
            result_field1="result",
            result_field2=3.14,
            status="success",
            details=[{"key": "value"}],
            timestamp="2025-05-01T12:00:00Z"
        )

        # Process task
        result = await agent.process_task(envelope)

        # Assert result
        assert result["status"] == "success"
        assert result["intent"] == "YOUR_INTENT_1"
        assert "result" in result
```

### Integration Testing

Create integration tests that validate the entire workflow, including Pub/Sub and Supabase interactions:

```python
@pytest.mark.integration
@pytest.mark.asyncio
async def test_agent_workflow():
    # Initialize real transports (using emulators)
    pubsub = PubSubTransport(project_id="test-project")
    supabase = SupabaseTransport(database_url="postgresql://user:pass@localhost:5432/postgres")
    policy = PolicyMiddleware()

    # Create agent
    agent = YourAgentName(
        pubsub_transport=pubsub,
        supabase_transport=supabase,
        policy_middleware=policy
    )

    # Start agent
    await agent.start()

    # Create test envelope
    envelope = A2AEnvelope(
        intent="YOUR_INTENT_1",
        content={
            "field1": "test value",
            "field2": 42,
            "option": "option_a"
        }
    )

    # Publish task
    await pubsub.publish_task(envelope)

    # Wait for processing
    await asyncio.sleep(2)

    # Check result in Supabase
    task_status = await supabase.get_task_status(envelope.task_id)
    assert task_status["status"] == "completed"

    # Cleanup
    await agent.stop()
```

## Monitoring and Observability

### Health Checks

Implement health check endpoints in your agent:

```python
from fastapi import FastAPI, HTTPException
from libs.agent_core import get_agent_health

app = FastAPI()

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    health = await get_agent_health()
    if health["status"] == "healthy":
        return health
    else:
        raise HTTPException(status_code=503, detail="Agent unhealthy")
```

### Metrics

Add Prometheus metrics to track agent performance:

```python
from prometheus_client import Counter, Histogram, Gauge
import time

# Define metrics
REQUESTS_TOTAL = Counter(
    'agent_requests_total',
    'Total number of requests processed',
    ['intent', 'status']
)

PROCESSING_TIME = Histogram(
    'agent_processing_seconds',
    'Time spent processing requests',
    ['intent']
)

ACTIVE_TASKS = Gauge(
    'agent_active_tasks',
    'Number of currently active tasks'
)

# Use metrics in your agent
async def process_task(self, envelope):
    ACTIVE_TASKS.inc()
    start_time = time.time()

    try:
        result = await self._process_task_internal(envelope)
        REQUESTS_TOTAL.labels(envelope.intent, "success").inc()
        return result
    except Exception as e:
        REQUESTS_TOTAL.labels(envelope.intent, "error").inc()
        raise
    finally:
        PROCESSING_TIME.labels(envelope.intent).observe(time.time() - start_time)
        ACTIVE_TASKS.dec()
```

### Distributed Tracing

Use OpenTelemetry for distributed tracing:

```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Set up tracer
provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter())
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)

# Use in your agent
async def process_task(self, envelope):
    with tracer.start_as_current_span(
        f"process_{envelope.intent}",
        context=trace.set_span_in_context(),
        attributes={
            "task_id": envelope.task_id,
            "intent": envelope.intent,
            "trace_id": envelope.trace_id
        }
    ) as span:
        try:
            result = await self._process_task_internal(envelope)
            span.set_status(trace.Status(trace.StatusCode.OK))
            return result
        except Exception as e:
            span.set_status(
                trace.Status(trace.StatusCode.ERROR, str(e))
            )
            span.record_exception(e)
            raise
```

## Error Handling and Resilience

Implement robust error handling and resilience strategies in your agent:

### Retry Logic

```python
import asyncio
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=1, max=10)
)
async def call_external_service(data):
    """Call external service with retry logic."""
    # Implementation here
    pass
```

### Circuit Breaker

```python
from circuitbreaker import circuit

@circuit(failure_threshold=5, recovery_timeout=30)
async def call_external_service(data):
    """Call external service with circuit breaker."""
    # Implementation here
    pass
```

### Dead Letter Queue

Set up a Dead Letter Queue (DLQ) for handling failed messages:

```python
async def _handle_message_with_dlq(self, envelope):
    try:
        await self._handle_message(envelope)
    except Exception as e:
        logger.error(
            "message_processing_failed",
            error=str(e),
            task_id=envelope.task_id
        )

        # Send to DLQ
        await self.pubsub.publish_task(
            envelope,
            topic=self.pubsub.dlq_topic_path
        )
```

### Graceful Degradation

Implement fallback mechanisms for when dependencies are unavailable:

```python
async def get_data(self, query):
    """Get data with fallback to cache if database is unavailable."""
    try:
        # Try primary source
        return await self.database.query(query)
    except DatabaseError:
        logger.warning("database_unavailable_using_cache")

        # Fall back to cache
        return await self.cache.get(query)
```

## State Management

### Managing Agent State with Supabase

```python
async def store_state(self, agent_id, state_data):
    """Store agent state in Supabase."""
    await self.supabase.execute(
        """
        INSERT INTO agent_state (agent_id, state_data, updated_at)
        VALUES (:agent_id, :state_data, :updated_at)
        ON CONFLICT (agent_id) DO UPDATE SET
            state_data = :state_data,
            updated_at = :updated_at
        """,
        {
            "agent_id": agent_id,
            "state_data": json.dumps(state_data),
            "updated_at": datetime.utcnow().isoformat() + "Z"
        }
    )

async def load_state(self, agent_id):
    """Load agent state from Supabase."""
    result = await self.supabase.fetchrow(
        "SELECT state_data FROM agent_state WHERE agent_id = :agent_id",
        {"agent_id": agent_id}
    )

    if result:
        return json.loads(result["state_data"])
    else:
        return {}
```

### Vector State Management

For storing and retrieving vector embeddings:

```python
async def store_embedding(self, task_id, embedding, metadata):
    """Store embedding in pgvector."""
    await self.supabase.execute(
        """
        INSERT INTO embeddings (task_id, embedding, metadata)
        VALUES (:task_id, :embedding, :metadata)
        """,
        {
            "task_id": task_id,
            "embedding": embedding,
            "metadata": json.dumps(metadata)
        }
    )

async def query_similar_embeddings(self, query_embedding, limit=5):
    """Query similar embeddings from pgvector."""
    results = await self.supabase.fetch(
        """
        SELECT task_id, metadata, embedding <-> :query_embedding AS distance
        FROM embeddings
        ORDER BY distance
        LIMIT :limit
        """,
        {
            "query_embedding": query_embedding,
            "limit": limit
        }
    )

    return [
        {
            "task_id": row["task_id"],
            "metadata": json.loads(row["metadata"]),
            "distance": row["distance"]
        }
        for row in results
    ]
```

## Documentation Requirements

Every agent should include:

1. **README.md**: Overview, purpose, and example usage
2. **API.md**: API documentation including intents and schema
3. **ARCHITECTURE.md**: Design, workflow, and integration details
4. **TESTING.md**: Testing approach and examples

### Example README.md

```markdown
# YourAgentName

## Overview

YourAgentName is responsible for [main purpose]. It supports [key capabilities] and integrates with [other systems].

## Intents

- `YOUR_INTENT_1`: [Description of intent 1]
- `YOUR_INTENT_2`: [Description of intent 2]

## Installation

```bash
# Installation instructions
```

## Usage

```python
# Example usage code
```

## Configuration

YourAgentName requires the following configuration:

- `API_KEY`: Your API key for external service
- `DATABASE_URL`: Supabase connection string
- `MODEL_NAME`: LLM model to use (default: "gpt-4")
```

## Agent Deployment Checklist

Before deploying your agent to production, ensure:

- [ ] All unit tests pass (>90% coverage)
- [ ] Integration tests validate end-to-end workflows
- [ ] Documentation is complete and up-to-date
- [ ] Error handling and retry logic is implemented
- [ ] Monitoring and metrics are set up
- [ ] Health check endpoints are implemented
- [ ] Policies and permissions are configured
- [ ] No sensitive data is logged
- [ ] Configuration is externalized (environment variables)
- [ ] Docker image builds successfully
- [ ] Agent registers successfully with the platform
- [ ] Performance testing has been conducted

### Deployment Steps

1. Build your Docker image:

```bash
docker build -t your-agent-name:latest .
```

2. Add to docker-compose.yml:

```yaml
services:
  your-agent-name:
    image: your-agent-name:latest
    restart: always
    environment:
      - SUPABASE_URL=http://supabase-db:5432
      - PUBSUB_EMULATOR_HOST=pubsub:8085
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    ports:
      - "9010:9010"
    depends_on:
      - supabase-db
      - pubsub
```

3. Deploy:

```bash
docker-compose up -d your-agent-name
```

4. Verify deployment:

```bash
curl http://localhost:9010/health
```

## Troubleshooting

### Common Issues

1. **Agent not receiving messages**:
   - Check Pub/Sub subscription and topic configuration
   - Verify agent is running and has started successfully
   - Check logs for subscription errors

2. **Task processing failures**:
   - Check for missing dependencies or configuration
   - Verify external API access (if applicable)
   - Review error logs for specific exception details

3. **Performance issues**:
   - Check resource utilization (CPU, memory)
   - Optimize LLM prompt templates
   - Implement caching for frequent operations

### Debugging

1. Enable debug logging:

```python
import logging
import structlog

structlog.configure(
    processors=[
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logging.basicConfig(level=logging.DEBUG)
```

2. Use distributed tracing:

```python
# Configure OpenTelemetry (see Monitoring section)
```

3. Validate task data:

```python
@app.get("/tasks/{task_id}")
async def get_task(task_id: str):
    """Get task details for debugging."""
    return await supabase.get_task_status(task_id)
```

---

## Conclusion

This guide provides a comprehensive overview of implementing new agents in the AI Agent Platform v2. By following these guidelines, you can create robust, scalable agents that integrate seamlessly with the platform's architecture and take advantage of its powerful features.

For additional support, contact the platform team via Slack or email.

---

*Last Updated: May 10, 2025*

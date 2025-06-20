# Agent Implementation Guide

**Last Updated:** 2025-05-10
**Owner:** Platform Team
**Status:** Active

## Overview

The Agent Implementation Guide provides comprehensive instructions for developing and deploying new agents within the Alfred Agent Platform v2. This guide serves as the definitive resource for developers implementing new agents in the platform, covering all aspects of the agent development lifecycle from setup to deployment.

The AI Agent Platform v2 is built on a modular, event-driven architecture that leverages Supabase for state storage and Pub/Sub for inter-agent communication. By following the standards and patterns outlined in this guide, developers can create robust, scalable agents that integrate seamlessly with the platform's architecture and take advantage of its powerful features.

This guide includes detailed instructions, code examples, architecture patterns, and best practices necessary to successfully implement agents that adhere to platform standards and can effectively communicate with other components of the system.

## Agent Development Metadata

| Attribute | Value |
|-----------|-------|
| Platform Version | v2.0+ |
| Required Skills | Python, Async Programming, LangChain/LangGraph |
| Development Time | 2-4 weeks (typical) |
| Testing Requirements | Unit tests (90%+ coverage), Integration tests |
| Documentation Requirements | README, API docs, Architecture docs, Testing docs |
| Status | Active |

## Architecture Overview

The AI Agent Platform v2 follows these key design principles:

- **Scalability**: Horizontal scaling across multiple containers or nodes
- **Modularity**: Loose coupling between components using standardized envelopes (A2A schema)
- **Flexibility & Extensibility**: Open standards and pluggable agents
- **Security & Privacy**: Role-based access control and data encryption
- **Observability & Monitoring**: End-to-end tracing and comprehensive metrics

### Core Components

| Component | Description | Role in Agent Implementation |
|-----------|-------------|------------------------------|
| **Agent Core Framework** | Base classes and utilities for agent implementation | Provides BaseAgent class and core functionality |
| **Transport Layer** | Google Cloud Pub/Sub for inter-agent communication | Handles message passing between agents |
| **State Storage** | Supabase (PostgreSQL with pgvector) for structured data and vector storage | Manages agent state and task information |
| **Vector Storage** | Qdrant for optimized vector searches | Supports semantic search capabilities |
| **AI Agent Framework** | LangChain for orchestration and LangGraph for complex workflows | Enables sophisticated agent workflows |
| **Observability** | LangSmith, Prometheus, Grafana, and OpenTelemetry | Provides monitoring and tracing |

### Agent Architecture Pattern

Agents in the platform follow a standardized architecture pattern:

```
┌──────────────────────────────────────────────────┐
│                  Your Agent                      │
│                                                  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  │
│  │ Intent     │  │ Processing │  │ Data       │  │
│  │ Handlers   │  │ Chains     │  │ Models     │  │
│  └──────┬─────┘  └─────┬──────┘  └────────────┘  │
│         │              │                         │
│         │              │                         │
│  ┌──────▼──────────────▼────────────────────┐    │
│  │             Workflow Graph                │    │
│  │ (LangGraph for orchestration)            │    │
│  └──────────────────┬───────────────────────┘    │
│                     │                            │
└─────────────────────┼────────────────────────────┘
                      │
┌─────────────────────▼────────────────────────────┐
│              Agent Core Framework                │
│                                                  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  │
│  │ A2A        │  │ State      │  │ Policy     │  │
│  │ Protocol   │  │ Management │  │ Middleware │  │
│  └────────────┘  └────────────┘  └────────────┘  │
└──────────────────────────────────────────────────┘
```

## Agent Implementation Steps

### 1. Set Up Your Development Environment

```bash
# Clone the repository (if not already done)
git clone https://github.com/your-org/alfred-agent-platform-v2.git
cd alfred-agent-platform-v2

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env with your configuration
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

### 3. Define Your Agent Capabilities and Intents

Before coding, define your agent's capabilities, responsibilities, and supported intents.

| Consideration | Description | Example |
|---------------|-------------|---------|
| **Primary Purpose** | Core responsibility of the agent | Financial analysis and tax calculations |
| **Supported Intents** | Specific tasks the agent can perform | TAX_CALCULATION, FINANCIAL_ANALYSIS |
| **Data Requirements** | Input data needed to perform tasks | Financial records, tax rules, user profile |
| **Integration Points** | Other systems or agents it interacts with | Legal Compliance Agent, Database |
| **Output Formats** | Expected response formats | JSON financial report, tax summary |

### 4. Implement Core Agent Classes

#### 4.1 Data Models (models.py)

Define Pydantic models for requests and responses:

```python
"""Data models for your agent"""

from enum import Enum
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field
from datetime import datetime

class AnalysisType(str, Enum):
    BASIC = "basic"
    DETAILED = "detailed"
    COMPREHENSIVE = "comprehensive"

class FinancialRequestModel(BaseModel):
    """Model for financial analysis request"""
    entity_id: str
    time_period: str
    analysis_type: AnalysisType = AnalysisType.BASIC
    include_forecasting: bool = False
    categories: List[str] = Field(default_factory=list)
    metadata: Dict[str, Any] = Field(default_factory=dict)

class FinancialResponseModel(BaseModel):
    """Model for financial analysis response"""
    entity_id: str
    time_period: str
    analysis_type: AnalysisType
    summary: Dict[str, float]
    details: Dict[str, List[Dict[str, Any]]] = Field(default_factory=dict)
    recommendations: List[str] = Field(default_factory=list)
    forecast: Optional[Dict[str, Any]] = None
    timestamp: str = Field(default_factory=lambda: datetime.utcnow().isoformat() + "Z")

# Add more models as needed
```

#### 4.2 Processing Chains (chains.py)

Implement LangChain-based processing chains:

```python
"""LangChain implementations for your agent"""

from typing import Dict, Any, List
from langchain.chains import LLMChain
from langchain.prompts import PromptTemplate
from langchain_openai import ChatOpenAI
from langchain.output_parsers import PydanticOutputParser
from .models import FinancialRequestModel, FinancialResponseModel

class FinancialAnalysisChain:
    """Chain for processing financial analysis"""

    def __init__(self, llm: ChatOpenAI = None):
        self.llm = llm or ChatOpenAI(temperature=0, model="gpt-4")
        self.output_parser = PydanticOutputParser(pydantic_object=FinancialResponseModel)

        self.prompt = PromptTemplate(
            template="""You are an expert financial analyst. Analyze the following financial information:

Entity ID: {entity_id}
Time Period: {time_period}
Analysis Type: {analysis_type}
Categories: {categories}
Additional Data: {metadata}

Provide a detailed financial analysis including:
1. Summary of key financial metrics
2. Detailed breakdown by category
3. Strategic recommendations
4. Future forecast (if requested)

{format_instructions}
""",
            input_variables=["entity_id", "time_period", "analysis_type", "categories", "metadata"],
            partial_variables={"format_instructions": self.output_parser.get_format_instructions()}
        )

        self.chain = LLMChain(llm=self.llm, prompt=self.prompt)

    async def process(self, request: FinancialRequestModel) -> FinancialResponseModel:
        """Process request"""
        result = await self.chain.arun(
            entity_id=request.entity_id,
            time_period=request.time_period,
            analysis_type=request.analysis_type.value,
            categories=request.categories,
            metadata=request.metadata
        )

        return self.output_parser.parse(result)
```

#### 4.3 Agent Implementation (agent.py)

Implement your main agent class:

```python
"""Your agent implementation"""

from typing import Dict, Any, List
import structlog
from langchain_openai import ChatOpenAI
from langgraph.graph import Graph, END

from libs.agent_core import BaseAgent
from libs.a2a_adapter import A2AEnvelope
from .chains import FinancialAnalysisChain
from .models import FinancialRequestModel, FinancialResponseModel

logger = structlog.get_logger(__name__)

class FinancialAgent(BaseAgent):
    """Agent for financial analysis and tax processing"""

    def __init__(self, *args, **kwargs):
        super().__init__(
            name="financial-agent",
            version="1.0.0",
            supported_intents=[
                "FINANCIAL_ANALYSIS",
                "TAX_CALCULATION",
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

        self.financial_analysis_chain = FinancialAnalysisChain(llm)
        # Initialize other chains

    def setup_graph(self):
        """Setup LangGraph for workflow orchestration"""
        self.workflow_graph = Graph()

        # Add nodes for different processing steps
        self.workflow_graph.add_node("parse_request", self._parse_request)
        self.workflow_graph.add_node("validate_data", self._validate_data)
        self.workflow_graph.add_node("process_financial_analysis", self._process_financial_analysis)
        self.workflow_graph.add_node("process_tax_calculation", self._process_tax_calculation)
        self.workflow_graph.add_node("format_response", self._format_response)

        # Add edges for workflow
        self.workflow_graph.add_edge("parse_request", "validate_data")

        # Add conditional edges based on intent
        self.workflow_graph.add_conditional_edges(
            "validate_data",
            self._route_by_intent,
            {
                "financial_analysis": "process_financial_analysis",
                "tax_calculation": "process_tax_calculation",
            }
        )

        # All processing nodes lead to format_response
        self.workflow_graph.add_edge("process_financial_analysis", "format_response")
        self.workflow_graph.add_edge("process_tax_calculation", "format_response")

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
        if intent == "FINANCIAL_ANALYSIS":
            return "financial_analysis"
        elif intent == "TAX_CALCULATION":
            return "tax_calculation"
        else:
            raise ValueError(f"Unsupported intent: {intent}")

    async def _process_financial_analysis(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """Process financial analysis request"""
        request = FinancialRequestModel(**state["parsed_content"])
        result = await self.financial_analysis_chain.process(request)
        state["result"] = result.dict()
        return state

    async def _process_tax_calculation(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """Process tax calculation request"""
        # Implement tax calculation logic
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

## A2A Communication Protocol

The Agent-to-Agent (A2A) protocol enables standardized communication between agents in the platform.

### A2A Envelope Schema

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

### Key A2A Fields

| Field | Purpose | Example |
|-------|---------|---------|
| **schema_version** | Version of schema | "0.4" |
| **task_id** | Unique identifier | "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d" |
| **intent** | Task purpose | "FINANCIAL_ANALYSIS" |
| **content** | Payload data | {"entity_id": "corp-123", "time_period": "Q2-2025"} |
| **artifacts** | Binary attachments | [{"type": "pdf", "content": "base64-encoded-content"}] |
| **trace_id** | Tracking identifier | "1b9d6bcd-bbfd-4b2d-9b5d-ab8dfbbd4bed" |
| **correlation_id** | Links related tasks | "07f7b51a-9d1f-4ec4-a43c-19d0823ae28b" |

### Creating an A2A Envelope

```python
from libs.a2a_adapter import A2AEnvelope

# Create a new envelope
envelope = A2AEnvelope(
    intent="FINANCIAL_ANALYSIS",
    content={
        "entity_id": "corp-123",
        "time_period": "Q2-2025",
        "analysis_type": "detailed",
        "include_forecasting": True,
        "categories": ["revenue", "expenses", "profit"]
    },
    metadata={
        "source": "financial-agent",
        "environment": "production"
    }
)
```

### Publishing and Subscribing

```python
# Publishing a task
message_id = await agent.publish_task(envelope)

# Subscribing to tasks
async def handle_message(envelope):
    result = await agent.process_task(envelope)
    # Handle result...

subscriber = await agent.subscribe("financial-tasks", handle_message)
```

## State Management

### Database Schema

The platform uses Supabase (PostgreSQL) for state management with these key tables:

| Table | Purpose | Sample Fields |
|-------|---------|--------------|
| **agent_registry** | Agent registration | name, version, capabilities, status |
| **tasks** | Task tracking | task_id, intent, status, created_at |
| **task_results** | Task results | task_id, result, completed_at |
| **agent_health** | Health tracking | agent_id, status, last_heartbeat |

### Agent Registration

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

### Task Tracking

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

### Vector Storage

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

async def search_similar(self, query_embedding, limit=5):
    """Search similar embeddings."""
    results = await self.execute(
        """
        SELECT task_id, metadata,
               (embedding <-> :query_embedding) as distance
        FROM embeddings
        ORDER BY distance ASC
        LIMIT :limit
        """,
        {
            "query_embedding": query_embedding,
            "limit": limit
        }
    )

    return results
```

## Error Handling and Resilience

### Retry Logic

```python
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

## Testing

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
def agent(mock_pubsub, mock_supabase):
    return YourAgentName(
        pubsub_transport=mock_pubsub,
        supabase_transport=mock_supabase
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

```python
@pytest.mark.integration
@pytest.mark.asyncio
async def test_agent_workflow():
    # Initialize real transports (using emulators)
    pubsub = PubSubTransport(project_id="test-project")
    supabase = SupabaseTransport(database_url="postgresql://user:pass@localhost:5432/postgres")

    # Create agent
    agent = YourAgentName(
        pubsub_transport=pubsub,
        supabase_transport=supabase
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

### Prometheus Metrics

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

### Health Checks

```python
from fastapi import FastAPI, HTTPException
from libs.agent_core import get_agent_health

app = FastAPI()

@app.get("/health/live")
async def liveness_check():
    """Basic liveness check."""
    return {"status": "alive"}

@app.get("/health/ready")
async def readiness_check():
    """Readiness check."""
    health = await get_agent_health()
    if health["status"] == "ready":
        return health
    else:
        raise HTTPException(status_code=503, detail="Agent not ready")

@app.get("/health/metrics")
async def metrics():
    """Get detailed metrics."""
    return await get_agent_metrics()
```

### Distributed Tracing

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

## Performance Considerations

### Agent Performance Profile

A well-implemented agent should meet these performance targets:

| Metric | Target | Notes |
|--------|--------|-------|
| Average Processing Time | < 2 seconds | For simple tasks without LLM calls |
| LLM-dependent Tasks | < 10 seconds | For tasks requiring LLM reasoning |
| Memory Usage | < 500MB | Per agent instance |
| Max Concurrent Tasks | 50+ | Configurable based on resources |
| Throughput | 10+ tasks/second | With optimized implementation |

### Optimization Techniques

Consider these optimization approaches:

1. **Caching**: Cache expensive LLM calls and common queries
2. **Batching**: Process similar requests in batches
3. **Streaming**: Use streaming responses for large outputs
4. **Parallelization**: Process independent tasks concurrently
5. **Efficient Prompting**: Optimize LLM prompts for efficiency
6. **Indexing**: Properly index database queries
7. **Connection Pooling**: Reuse database connections

## Documentation Requirements

Every agent should include comprehensive documentation:

### 1. README.md

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

### 2. API.md

Document all supported intents, input schemas, and response formats.

### 3. ARCHITECTURE.md

Document the internal architecture, components, and data flow.

### 4. TESTING.md

Document the testing approach, test cases, and coverage goals.

## Deployment

### Containerization

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "-m", "your_agent.main"]
```

### Docker Compose Integration

```yaml
services:
  your-agent-name:
    build:
      context: .
      dockerfile: Dockerfile
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

### Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `SUPABASE_URL` | Supabase connection URL | `http://supabase-db:5432` |
| `PUBSUB_EMULATOR_HOST` | Pub/Sub emulator host | `pubsub:8085` |
| `OPENAI_API_KEY` | OpenAI API key | `sk-...` |
| `LOG_LEVEL` | Logging level | `info` |
| `MAX_CONCURRENT_TASKS` | Task concurrency limit | `50` |

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

## Troubleshooting

### Common Issues

| Issue | Possible Causes | Resolution |
|-------|----------------|------------|
| Agent not receiving messages | Pub/Sub subscription issues | Verify topic and subscription configuration |
| Task processing failures | Missing dependencies | Check logs for specific errors, ensure all dependencies are installed |
| Performance issues | Resource constraints | Check resource utilization, optimize code, increase resources |
| Database connection errors | Configuration issues | Verify connection strings and credentials |
| Authentication failures | Invalid API keys | Check API key configuration |

### Debugging Tools

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

2. Task inspection endpoint:

```python
@app.get("/tasks/{task_id}")
async def get_task(task_id: str):
    """Get task details for debugging."""
    return await supabase.get_task_status(task_id)
```

## Related Documentation

- [Agent Core Framework](../architecture/agent-core.md)
- [A2A Protocol Documentation](../api/a2a-protocol.md)
- [System Architecture](../architecture/system-architecture.md)
- [Social Intelligence Agent](../agents/architect-apiligence-agent.md)
- [Financial-Tax Agent](../agents/financial-tax-agent.md)

## References

- [LangChain Documentation](https://python.langchain.com/docs/get_started/introduction.html)
- [LangGraph Documentation](https://python.langchain.com/docs/langgraph)
- [Supabase Documentation](https://supabase.io/docs)
- [Google Cloud Pub/Sub Documentation](https://cloud.google.com/pubsub/docs)
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)

---

*Last Updated: 2025-05-10*

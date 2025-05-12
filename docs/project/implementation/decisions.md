# Implementation Decisions Document

This document addresses the open questions identified in the plan review and provides concrete decisions to unblock development.

## Source-of-Truth Repositories

**DECISION**: Mono-repo approach for core components, with clear boundaries.

```
/projects/alfred-agent-platform-v2/
├── services/
│   ├── alfred-bot/                  # Enhanced Slack bot implementation
│   ├── alfred-orchestrator/         # Core orchestration service (formerly agent-orchestrator)
│   └── atlas-worker/                # Existing Atlas RAG service
├── ui/
│   ├── mission-control/             # Primary Next.js UI (existing)
│   └── streamlit-chat/              # Demo/testing tool only (new)
└── libs/
    ├── a2a_adapter/                 # Shared adapter library (existing)
    ├── agent_core/                  # Agent core functionality (existing)
    └── observability/               # Shared monitoring tools (existing)
```

**RATIONALE**:
- Maintaining a mono-repo structure reduces CI/CD complexity
- Allows sharing of common libraries (a2a_adapter, agent_core)
- Enables atomic commits across related components
- Simplifies dependency management and version coordination

## Mission-Control vs Streamlit

**DECISION**: Streamlit UI is a **development/testing tool only**, not a production UI.

| UI | Purpose | Audience | Lifecycle |
|----|---------|----------|-----------|
| Mission Control | Production UI for all platform capabilities | End-users, Administrators | Long-term, maintained |
| Streamlit Chat | Development testing tool for conversation flows | Developers, QA | Temporary, may be deprecated |

**IMPLEMENTATION STEPS**:
1. Add a clear "DEVELOPMENT TOOL ONLY" banner to Streamlit UI
2. Document integration points for Mission Control to consume the same API
3. Create a simple adapter in Mission Control UI to use the enhanced alfred-bot API

**RATIONALE**:
- Avoids duplicated effort on UI components
- Streamlit provides rapid development for testing conversation flows
- Mission Control remains the canonical UI for production use

## HTTP Tunneling Solution

**DECISION**: Replace ngrok with the following approach:

| Environment | Solution | Implementation |
|-------------|----------|----------------|
| Development | ngrok | Used for local development only |
| Staging | Cloudflare Tunnel | Configured with zero-trust access policies |
| Production | Native Ingress + Load Balancer | GKE Ingress with managed certificate |

**IMPLEMENTATION DETAILS**:
```yaml
# staging/cloudflare-tunnel.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cloudflared-config
data:
  config.yaml: |
    tunnel: alfred-slack-staging
    credentials-file: /etc/cloudflared/creds/credentials.json
    ingress:
      - hostname: alfred-slack-staging.example.com
        service: http://alfred-bot.default.svc.cluster.local:8011
      - service: http_status:404
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudflared
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cloudflared
  template:
    metadata:
      labels:
        app: cloudflared
    spec:
      containers:
        - name: cloudflared
          image: cloudflare/cloudflared:latest
          args:
            - tunnel
            - --config
            - /etc/cloudflared/config/config.yaml
            - run
          volumeMounts:
            - name: config
              mountPath: /etc/cloudflared/config
              readOnly: true
            - name: creds
              mountPath: /etc/cloudflared/creds
              readOnly: true
      volumes:
        - name: config
          configMap:
            name: cloudflared-config
        - name: creds
          secret:
            secretName: cloudflared-credentials
```

**RATIONALE**:
- ngrok is unsuitable for production (stability, IP allow-listing)
- Cloudflare Tunnel provides better security and reliability for staging
- Native ingress with managed certificates is the most robust solution for production

## RAG Service Contract

**DECISION**: Use the existing Atlas RAG Gateway with the following contract:

**Endpoint**: `http://atlas-rag-gateway:8501/api/query`

**Request Schema**:
```json
{
  "query": "User's question or input",
  "collection": "alfred-personal",
  "top_k": 15,
  "relevancy_threshold": 0.65,
  "context": {
    "user_id": "U123456",
    "channel_id": "C123456",
    "tenant": "personal"
  }
}
```

**Response Schema**:
```json
{
  "query": "User's question or input",
  "documents": [
    {
      "content": "Document text content",
      "metadata": {
        "source": "document-source.md",
        "created_at": "2025-05-10T12:34:56Z",
        "author": "Author Name"
      },
      "relevance_score": 0.85
    }
  ],
  "relevance_score": 0.78
}
```

**Circuit-Breaker Policy**:
- Timeout: 2 seconds
- Max retries: 1
- Fallback: Return empty document list with relevance_score of 0
- Health check: Ping `/health` endpoint every 30 seconds
- Circuit open: After 5 consecutive failures
- Recovery: Half-open after a 30-second cooldown period

**IMPLEMENTATION**:
```python
from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import httpx
import asyncio
import time
from functools import wraps

# Circuit breaker implementation
class CircuitBreaker:
    def __init__(self, failure_threshold=5, recovery_time=30):
        self.failure_threshold = failure_threshold
        self.recovery_time = recovery_time
        self.failures = 0
        self.state = "closed"
        self.last_failure_time = 0
    
    def __call__(self, func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            if self.state == "open":
                if time.time() - self.last_failure_time > self.recovery_time:
                    # Move to half-open state
                    self.state = "half-open"
                else:
                    # Circuit is open, return fallback
                    return self.fallback(*args, **kwargs)
            
            try:
                result = await func(*args, **kwargs)
                if self.state == "half-open":
                    # Success in half-open state, reset circuit
                    self.failures = 0
                    self.state = "closed"
                return result
            except Exception as e:
                self.failures += 1
                self.last_failure_time = time.time()
                if self.failures >= self.failure_threshold or self.state == "half-open":
                    self.state = "open"
                raise e
        
        return wrapper
    
    def fallback(self, *args, **kwargs):
        # Default fallback implementation
        return {
            "query": args[0] if args else "",
            "documents": [],
            "relevance_score": 0
        }

# RAG adapter with circuit breaker
rag_circuit = CircuitBreaker(failure_threshold=5, recovery_time=30)

class RAGAdapter:
    def __init__(self, base_url, api_key, timeout=2.0):
        self.base_url = base_url
        self.api_key = api_key
        self.timeout = timeout
    
    @rag_circuit
    async def query(self, query_text, collection, top_k=15, context=None):
        """Query the RAG service with circuit breaker protection."""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(
                f"{self.base_url}/api/query",
                headers={"X-API-Key": self.api_key},
                json={
                    "query": query_text,
                    "collection": collection,
                    "top_k": top_k,
                    "context": context or {}
                }
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                raise Exception(f"RAG query failed: {response.text}")
```

**RATIONALE**:
- Defines a clear contract for RAG service integration
- Implements a circuit breaker to prevent cascading failures
- Provides a fallback for RAG service unavailability
- Sets reasonable timeouts to prevent blocking the conversation flow

## Supabase Schema & Access

**DECISION**: Use the following Supabase schema for conversation storage:

```sql
-- Create conversations table for storing conversation metadata
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,
    channel_id TEXT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb,
    interface TEXT NOT NULL,
    tenant TEXT NOT NULL DEFAULT 'personal'
);

-- Create messages table for storing individual messages
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_type TEXT NOT NULL, -- 'user' or 'bot'
    content TEXT NOT NULL,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create user_state table for storing user preferences and state
CREATE TABLE user_state (
    user_id TEXT PRIMARY KEY,
    preferences JSONB DEFAULT '{}'::jsonb,
    last_interaction TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create RLS policies for tenant isolation
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON conversations
    USING (tenant = current_setting('app.tenant', TRUE));

CREATE POLICY conversation_access ON messages
    USING (conversation_id IN (
        SELECT id FROM conversations WHERE tenant = current_setting('app.tenant', TRUE)
    ));

-- Create indexes for performance
CREATE INDEX idx_conversations_user_id ON conversations(user_id);
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_sent_at ON messages(sent_at);
```

**Access Method**:
- Use service role key for alfred-bot (full access)
- Set `app.tenant` setting for each request to enforce tenant isolation
- Use separate schema for each deployment environment (dev, staging, prod)

**IMPLEMENTATION**:
```python
import asyncpg
import os
from typing import Dict, Any, List, Optional

class SupabaseAdapter:
    """Adapter for Supabase database operations."""
    
    def __init__(self):
        self.connection_string = os.environ.get("DATABASE_URL")
        self.tenant = os.environ.get("TENANT", "personal")
        self.pool = None
    
    async def connect(self):
        """Establish connection pool to database."""
        self.pool = await asyncpg.create_pool(self.connection_string)
    
    async def disconnect(self):
        """Close database connection pool."""
        if self.pool:
            await self.pool.close()
    
    async def create_conversation(self, user_id: str, channel_id: str, interface: str, metadata: Dict[str, Any] = None) -> str:
        """Create a new conversation and return its ID."""
        async with self.pool.acquire() as conn:
            # Set tenant for RLS
            await conn.execute(f"SET LOCAL app.tenant = '{self.tenant}'")
            
            # Create conversation
            conversation_id = await conn.fetchval(
                """
                INSERT INTO conversations (user_id, channel_id, interface, metadata, tenant)
                VALUES ($1, $2, $3, $4, $5)
                RETURNING id
                """,
                user_id, channel_id, interface, metadata or {}, self.tenant
            )
            
            return conversation_id
    
    async def add_message(self, conversation_id: str, sender_type: str, content: str, metadata: Dict[str, Any] = None) -> str:
        """Add a message to a conversation and return its ID."""
        async with self.pool.acquire() as conn:
            # Set tenant for RLS
            await conn.execute(f"SET LOCAL app.tenant = '{self.tenant}'")
            
            # Add message
            message_id = await conn.fetchval(
                """
                INSERT INTO messages (conversation_id, sender_type, content, metadata)
                VALUES ($1, $2, $3, $4)
                RETURNING id
                """,
                conversation_id, sender_type, content, metadata or {}
            )
            
            # Update conversation timestamp
            await conn.execute(
                """
                UPDATE conversations SET updated_at = NOW()
                WHERE id = $1
                """,
                conversation_id
            )
            
            return message_id
```

**RATIONALE**:
- Schema design supports conversation history and user state
- Row-level security provides tenant isolation
- Indexes optimize common query patterns
- Implementation follows project standards

## A2A Envelope & Routing

**DECISION**: Use the following A2A envelope format for message passing:

**A2A Request Envelope**:
```json
{
  "task_id": "task-1684721588-8f7a",
  "intent": "CONVERSATION",
  "content": {
    "message": "Tell me about the financial markets",
    "user_id": "U123456",
    "channel_id": "C123456",
    "thread_ts": "1684721588.123456",
    "interface": "slack"
  },
  "metadata": {
    "priority": "normal",
    "timeout_seconds": 60,
    "originating_service": "alfred-bot",
    "trace_id": "trace-1684721588-8f7a"
  },
  "timestamp": "2025-05-12T15:23:45.123Z"
}
```

**A2A Response Envelope**:
```json
{
  "task_id": "task-1684721588-8f7a",
  "intent": "CONVERSATION_RESPONSE",
  "content": {
    "message": "The financial markets today are showing mixed trends...",
    "user_id": "U123456",
    "channel_id": "C123456",
    "thread_ts": "1684721588.123456",
    "blocks": [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "The financial markets today are showing mixed trends..."
        }
      }
    ]
  },
  "metadata": {
    "response_time_ms": 1250,
    "source_agent": "financial-tax",
    "trace_id": "trace-1684721588-8f7a"
  },
  "timestamp": "2025-05-12T15:23:46.456Z"
}
```

**Routing Logic**:

| Intent | Primary Route | Fallback |
|--------|--------------|----------|
| CONVERSATION | Determine from content | alfred-orchestrator |
| TREND_ANALYSIS | social-intel | alfred-orchestrator |
| TAX_QUESTION | financial-tax | alfred-orchestrator |
| LEGAL_QUESTION | legal-compliance | alfred-orchestrator |

**IMPLEMENTATION**:
```python
# /projects/alfred-agent-platform-v2/libs/a2a_adapter/envelope.py
from typing import Dict, Any, Optional, List
import uuid
import time
import json
from datetime import datetime, timezone

class A2AEnvelope:
    """A2A message envelope for inter-agent communication."""
    
    def __init__(
        self,
        intent: str,
        content: Dict[str, Any],
        metadata: Optional[Dict[str, Any]] = None,
        task_id: Optional[str] = None
    ):
        self.task_id = task_id or f"task-{int(time.time())}-{uuid.uuid4().hex[:4]}"
        self.intent = intent
        self.content = content
        self.metadata = metadata or {
            "priority": "normal",
            "timeout_seconds": 60,
            "originating_service": "unknown",
            "trace_id": f"trace-{int(time.time())}-{uuid.uuid4().hex[:4]}"
        }
        self.timestamp = datetime.now(timezone.utc).isoformat()
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'A2AEnvelope':
        """Create an envelope from a dictionary."""
        return cls(
            intent=data.get("intent"),
            content=data.get("content", {}),
            metadata=data.get("metadata", {}),
            task_id=data.get("task_id")
        )
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert envelope to a dictionary."""
        return {
            "task_id": self.task_id,
            "intent": self.intent,
            "content": self.content,
            "metadata": self.metadata,
            "timestamp": self.timestamp
        }
    
    def to_json(self) -> str:
        """Convert envelope to a JSON string."""
        return json.dumps(self.to_dict())
```

**RATIONALE**:
- Standardizes communication format across all agents
- Includes necessary metadata for tracing and monitoring
- Provides clear routing logic for different intents
- Implements serialization/deserialization for transport

## Secrets Management

**DECISION**: Use the following secrets management approach:

| Environment | Storage | Access Method | Rotation |
|-------------|---------|---------------|----------|
| Development | .env file + .env.dev | Local file | Manual |
| CI/CD | GitHub Actions Secrets | Repository secrets | Manual |
| Staging | Fly.io secrets | fly secrets set | 30-day automated |
| Production | Google Secret Manager | GKE workload identity | 30-day automated |

**Specific Secrets Required**:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| SLACK_BOT_TOKEN | OAuth token for Slack bot | xoxb-123... |
| SLACK_SIGNING_SECRET | Signing secret for verifying Slack requests | a1b2c3... |
| SLACK_APP_TOKEN | App-level token for Slack | xapp-123... |
| DATABASE_URL | Supabase PostgreSQL connection string | postgresql://... |
| SUPABASE_SERVICE_ROLE_KEY | Service role key for Supabase | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... |
| REDIS_URL | Redis connection string | redis://redis:6379/0 |
| RAG_URL | URL for RAG service | http://atlas-rag-gateway:8501 |
| ALFRED_RAG_API_KEY | API key for RAG service | rag-key-123 |
| OPENAI_API_KEY | API key for OpenAI | sk-... |

**IMPLEMENTATION**:
```bash
#!/bin/bash
# secrets-setup.sh - Script to set up secrets for different environments

# Development
cp .env.example .env.dev
echo "Edit .env.dev with your development secrets"

# CI/CD
echo "Add the following secrets to GitHub repository:"
echo "- SLACK_BOT_TOKEN"
echo "- SLACK_SIGNING_SECRET"
echo "- SLACK_APP_TOKEN"
echo "- DATABASE_URL"
echo "- SUPABASE_SERVICE_ROLE_KEY"
echo "- REDIS_URL"
echo "- RAG_URL"
echo "- ALFRED_RAG_API_KEY"
echo "- OPENAI_API_KEY"

# Staging (Fly.io)
echo "Run the following commands to set up Fly.io secrets:"
echo "fly secrets set SLACK_BOT_TOKEN=xoxb-..."
echo "fly secrets set SLACK_SIGNING_SECRET=a1b2c3..."
echo "fly secrets set SLACK_APP_TOKEN=xapp-..."
echo "fly secrets set DATABASE_URL=postgresql://..."
echo "fly secrets set SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
echo "fly secrets set REDIS_URL=redis://redis:6379/0"
echo "fly secrets set RAG_URL=http://atlas-rag-gateway:8501"
echo "fly secrets set ALFRED_RAG_API_KEY=rag-key-123"
echo "fly secrets set OPENAI_API_KEY=sk-..."

# Production (Google Secret Manager)
echo "Run the following commands to set up Google Secret Manager secrets:"
echo "gcloud secrets create slack-bot-token --replication-policy=automatic"
echo "gcloud secrets versions add slack-bot-token --data-file=/tmp/slack-bot-token.txt"
echo "gcloud secrets create slack-signing-secret --replication-policy=automatic"
echo "gcloud secrets versions add slack-signing-secret --data-file=/tmp/slack-signing-secret.txt"
echo "..."
```

**Rotation Policy Document** (to be created at `/docs/ops/secrets.md`):
```markdown
# Secrets Management

## Overview
This document outlines the secrets management strategy for the Alfred Agent Platform.

## Secret Rotation Schedule

| Secret Type | Rotation Frequency | Responsible Team | Procedure |
|-------------|-------------------|------------------|-----------|
| Slack Tokens | 90 days | Platform Team | Manually rotate in Slack admin console |
| API Keys (OpenAI, etc.) | 30 days | Security Team | Automated rotation via CI/CD |
| Database Credentials | 90 days | DBA Team | Automated rotation script |
| Service Tokens | 30 days | Security Team | Automated rotation via CI/CD |

## Rotation Procedure

1. Generate new secret value
2. Update secret in storage (GitHub Actions, Fly.io, Google Secret Manager)
3. Deploy services with new secret
4. Verify functionality
5. Revoke old secret
6. Document rotation in rotation log

## Emergency Rotation

In case of suspected compromise:

1. Generate new secret immediately
2. Deploy emergency update
3. Revoke old secret
4. Run security audit
5. File incident report

## Access Control

| Role | Access Level | Secret Types |
|------|-------------|--------------|
| Admin | Full | All secrets |
| Developer | Read | Development environment only |
| CI/CD | Write | CI/CD environment only |
```

**RATIONALE**:
- Provides a clear strategy for managing secrets across environments
- Defines rotation policies and responsibilities
- Follows security best practices for secret management
- Automates rotation where possible to reduce manual overhead

## Monitoring Stack

**DECISION**: Use the following monitoring setup:

**Prometheus Metrics**:

| Metric | Type | Description | Labels |
|--------|------|-------------|--------|
| alfred_bot_requests_total | Counter | Total number of requests processed | method, endpoint, status |
| alfred_bot_response_time_seconds | Histogram | Response time in seconds | method, endpoint |
| alfred_bot_active_users | Gauge | Number of active users in the last 5 minutes | tenant |
| alfred_bot_rag_query_time_seconds | Histogram | RAG query time in seconds | collection, status |
| alfred_bot_rag_query_total | Counter | Total number of RAG queries | collection, status |
| alfred_bot_a2a_messages_total | Counter | Total number of A2A messages | intent, status |
| alfred_bot_a2a_message_time_seconds | Histogram | A2A message round-trip time | intent |

**Grafana Dashboard**:

- Dashboard ID: 15721 (reserved)
- Dashboard Name: "Alfred Bot Operations"
- Panels:
  - Request Rate by Endpoint
  - Response Time by Endpoint
  - Active Users
  - RAG Query Performance
  - A2A Message Flow
  - Error Rate
  - Circuit Breaker Status

**Prometheus Scrape Configuration**:
```yaml
# prometheus/prometheus.yml
scrape_configs:
  - job_name: 'alfred-bot'
    metrics_path: '/metrics'
    scheme: http
    static_configs:
      - targets: ['alfred-bot:8011']
        labels:
          service: 'alfred-bot'
          environment: 'production'
```

**IMPLEMENTATION**:
```python
# services/alfred-bot/app/utils/monitoring.py
from prometheus_client import Counter, Histogram, Gauge, Summary
from prometheus_client import make_asgi_app
from fastapi import FastAPI
import time
import functools

# Define metrics
REQUEST_COUNT = Counter(
    'alfred_bot_requests_total',
    'Count of requests received',
    ['method', 'endpoint', 'status']
)

REQUEST_LATENCY = Histogram(
    'alfred_bot_response_time_seconds',
    'Histogram of request processing time',
    ['method', 'endpoint']
)

ACTIVE_USERS = Gauge(
    'alfred_bot_active_users',
    'Number of users interacting with the bot in the last 5 minutes',
    ['tenant']
)

RAG_QUERY_LATENCY = Histogram(
    'alfred_bot_rag_query_time_seconds',
    'Histogram of RAG query processing time',
    ['collection', 'status']
)

RAG_QUERY_COUNT = Counter(
    'alfred_bot_rag_query_total',
    'Count of RAG queries',
    ['collection', 'status']
)

A2A_MESSAGE_COUNT = Counter(
    'alfred_bot_a2a_messages_total',
    'Count of A2A messages',
    ['intent', 'status']
)

A2A_MESSAGE_LATENCY = Histogram(
    'alfred_bot_a2a_message_time_seconds',
    'Histogram of A2A message round-trip time',
    ['intent']
)

def setup_monitoring(app: FastAPI):
    """Set up monitoring for a FastAPI app."""
    # Add Prometheus metrics endpoint
    metrics_app = make_asgi_app()
    app.mount("/metrics", metrics_app)
    
    # Add middleware for request tracking
    @app.middleware("http")
    async def monitor_requests(request, call_next):
        method = request.method
        path = request.url.path
        
        start_time = time.time()
        
        try:
            response = await call_next(request)
            status_code = response.status_code
            REQUEST_COUNT.labels(method, path, status_code).inc()
        except Exception as e:
            status_code = 500
            REQUEST_COUNT.labels(method, path, status_code).inc()
            raise e
        finally:
            latency = time.time() - start_time
            REQUEST_LATENCY.labels(method, path).observe(latency)
        
        return response
    
    return app
```

**RATIONALE**:
- Provides comprehensive metrics for monitoring
- Follows standard Prometheus patterns
- Integrates with existing monitoring stack
- Enables alerting and dashboarding for operations

## Testing Targets

**DECISION**: Implement the following testing strategy:

| Test Type | Coverage Target | Tools | CI Enforcement |
|-----------|----------------|-------|----------------|
| Unit Tests | ≥80% | pytest, pytest-cov | Required to pass |
| Integration Tests | ≥70% | pytest, testcontainers | Required to pass |
| E2E Tests | Key workflows only | pytest, playwright | Required to pass |
| Load Tests | N/A | locust | Run weekly, non-blocking |

**Key E2E Test Cases**:

1. **Slash Command Flow**:
   - Send `/alfred help` command to bot
   - Verify appropriate response
   - Check database record creation

2. **DM Conversation Flow**:
   - Send direct message to bot
   - Verify response with rich formatting
   - Check conversation threading

3. **RAG Integration**:
   - Send knowledge-based question
   - Verify RAG service is queried
   - Check response includes relevant context

4. **A2A Communication**:
   - Send task that requires Social Intelligence
   - Verify envelope is properly formatted
   - Check task completion and response

**IMPLEMENTATION**:
```python
# services/alfred-bot/tests/test_integration.py
import pytest
import os
import json
from httpx import AsyncClient
from fastapi.testclient import TestClient
from unittest.mock import patch, AsyncMock

from app.main import app

@pytest.fixture
def test_client():
    return TestClient(app)

@pytest.mark.integration
async def test_slash_command_help(test_client):
    """Test the /alfred help command flow."""
    # Mock Slack API
    with patch("slack_bolt.App.client") as mock_client:
        mock_client.chat_postMessage = AsyncMock()
        
        # Send request
        response = await test_client.post(
            "/slack/events",
            json={
                "type": "command",
                "command": "/alfred",
                "text": "help",
                "user_id": "U123456",
                "channel_id": "C123456"
            },
            headers={"X-Slack-Signature": "v0=test", "X-Slack-Request-Timestamp": "123456"}
        )
        
        # Verify response
        assert response.status_code == 200
        
        # Verify Slack API call
        mock_client.chat_postMessage.assert_called_once()
        args, kwargs = mock_client.chat_postMessage.call_args
        assert kwargs["channel"] == "C123456"
        assert "help" in str(kwargs["blocks"]).lower()

@pytest.mark.e2e
@pytest.mark.skipif(not os.getenv("RUN_E2E_TESTS"), reason="E2E tests disabled")
async def test_e2e_dm_conversation():
    """End-to-end test for direct message conversation flow."""
    # This requires actual Slack credentials and a test workspace
    from slack_sdk import WebClient
    
    client = WebClient(token=os.environ["SLACK_BOT_TOKEN"])
    
    # Send message to test bot
    response = client.chat_postMessage(
        channel=os.environ["TEST_DM_CHANNEL"],
        text="Hello, this is an E2E test message"
    )
    
    # Get message timestamp for thread identification
    ts = response["ts"]
    
    # Wait for bot response (in real test, use proper waiting mechanism)
    import time
    time.sleep(2)
    
    # Check for response in thread
    history = client.conversations_history(
        channel=os.environ["TEST_DM_CHANNEL"],
        latest=ts,
        limit=1,
        inclusive=True
    )
    
    # Verify response
    assert len(history["messages"]) > 0
    assert "hello" in history["messages"][0]["text"].lower()
```

**RATIONALE**:
- Sets clear coverage targets
- Identifies critical test cases
- Provides implementation examples
- Follows project testing standards

## Timeline & Owners

**DECISION**: Implement the following project timeline:

### Phase 1: Setup & Infrastructure (Week 1)

| Task | Owner | Timeline | Dependencies |
|------|-------|----------|--------------|
| Create skeletal repos with READMEs | DevOps Engineer | Day 1-2 | None |
| Stub API endpoints & schemas | Backend Engineer | Day 2-3 | Repos created |
| Create Docker build pipeline | DevOps Engineer | Day 3-4 | Repos created |
| Set up secrets management | Security Engineer | Day 3-5 | None |
| Configure monitoring stack | DevOps Engineer | Day 4-5 | Docker pipeline |

### Phase 2: Core Implementation (Week 2-3)

| Task | Owner | Timeline | Dependencies |
|------|-------|----------|--------------|
| Implement enhanced Slack bot | Backend Engineer | Week 2 | API endpoints, Secrets |
| Develop RAG integration | ML Engineer | Week 2 | API endpoints, Secrets |
| Create Supabase schema | Database Engineer | Week 2 | None |
| Implement A2A integration | Backend Engineer | Week 2-3 | API endpoints |
| Develop Streamlit UI | Frontend Engineer | Week 2-3 | API endpoints |
| Set up Cloudflare Tunnel | DevOps Engineer | Week 3 | None |

### Phase 3: Testing & Integration (Week 4)

| Task | Owner | Timeline | Dependencies |
|------|-------|----------|--------------|
| Write unit tests | Quality Engineer | Week 4 | All implementations |
| Implement integration tests | Quality Engineer | Week 4 | All implementations |
| Create E2E test suite | Quality Engineer | Week 4 | All implementations |
| Update documentation | Technical Writer | Week 4 | All implementations |
| Perform security review | Security Engineer | Week 4 | All implementations |

### Phase 4: Deployment & Handover (Week 5)

| Task | Owner | Timeline | Dependencies |
|------|-------|----------|--------------|
| Staging deployment | DevOps Engineer | Day 1-2 | Testing complete |
| Load testing | Quality Engineer | Day 2-3 | Staging deployment |
| Production deployment | DevOps Engineer | Day 3-4 | Load testing |
| Handover documentation | Technical Writer | Day 4-5 | Production deployment |
| Training session | Product Manager | Day 5 | Handover documentation |

**RATIONALE**:
- Provides a clear timeline for implementation
- Assigns specific owners to tasks
- Identifies dependencies between tasks
- Allows for proper resource planning

## Immediate Action Items

1. **Create Skeletal Repos**:
   ```bash
   # Create directories
   mkdir -p services/alfred-bot
   mkdir -p services/alfred-orchestrator
   mkdir -p ui/streamlit-chat
   
   # Create basic READMEs
   echo "# Alfred Bot\n\nEnhanced Slack bot for the Alfred Agent Platform." > services/alfred-bot/README.md
   echo "# Alfred Orchestrator\n\nCentral orchestration service for the Alfred Agent Platform." > services/alfred-orchestrator/README.md
   echo "# Streamlit Chat UI\n\nDevelopment and testing UI for the Alfred Agent Platform." > ui/streamlit-chat/README.md
   
   # Create Dockerfiles
   cp /home/locotoki/projects/alfred-agent-platform-v2/services/alfred-bot/Dockerfile services/alfred-bot/
   cp /home/locotoki/projects/alfred-agent-platform-v2/services/agent-orchestrator/Dockerfile services/alfred-orchestrator/
   touch ui/streamlit-chat/Dockerfile
   ```

2. **Create A2A Envelope Stub**:
   ```bash
   mkdir -p docs/protocol
   
   # Create A2A envelope JSON example
   cat > docs/protocol/a2a-envelope-example.json << 'EOF'
   {
     "task_id": "task-1684721588-8f7a",
     "intent": "CONVERSATION",
     "content": {
       "message": "Tell me about the financial markets",
       "user_id": "U123456",
       "channel_id": "C123456",
       "thread_ts": "1684721588.123456",
       "interface": "slack"
     },
     "metadata": {
       "priority": "normal",
       "timeout_seconds": 60,
       "originating_service": "alfred-bot",
       "trace_id": "trace-1684721588-8f7a"
     },
     "timestamp": "2025-05-12T15:23:45.123Z"
   }
   EOF
   
   # Create README
   cat > docs/protocol/README.md << 'EOF'
   # A2A Protocol Documentation
   
   This directory contains documentation and examples for the Agent-to-Agent (A2A) communication protocol.
   
   ## Overview
   
   The A2A protocol is a standardized message format for communication between agents in the Alfred Agent Platform.
   
   ## Envelope Structure
   
   - `task_id`: Unique identifier for the task
   - `intent`: Purpose of the message
   - `content`: Message payload
   - `metadata`: Additional information about the message
   - `timestamp`: ISO 8601 timestamp
   
   ## Example
   
   See `a2a-envelope-example.json` for a complete example.
   EOF
   ```

3. **Update Tunnel Solution**:
   ```bash
   # Create Cloudflare Tunnel documentation
   mkdir -p docs/ops
   
   cat > docs/ops/tunnel-configuration.md << 'EOF'
   # HTTP Tunneling Configuration
   
   ## Overview
   
   This document outlines the HTTP tunneling solutions for different environments in the Alfred Agent Platform.
   
   ## Development Environment
   
   For local development, developers can use ngrok to expose their local services.
   
   ### Setup
   
   ```bash
   # Install ngrok
   curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
   echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
   sudo apt update && sudo apt install ngrok
   
   # Configure ngrok
   ngrok config add-authtoken YOUR_NGROK_AUTH_TOKEN
   
   # Start tunnel
   ngrok http 8011
   ```
   
   ## Staging Environment
   
   Staging uses Cloudflare Tunnel for secure access.
   
   ### Setup
   
   See `cloudflare-tunnel.yaml` in the staging directory for Kubernetes configuration.
   
   ## Production Environment
   
   Production uses native Kubernetes Ingress with managed certificates.
   
   ### Setup
   
   See `ingress.yaml` in the production directory for Kubernetes configuration.
   EOF
   ```

4. **Create UI Alignment Document**:
   ```bash
   # Create UI alignment document
   mkdir -p docs/ui
   
   cat > docs/ui/ui-strategy.md << 'EOF'
   # UI Strategy
   
   ## Overview
   
   This document outlines the UI strategy for the Alfred Agent Platform.
   
   ## UI Components
   
   ### Mission Control UI
   
   The Mission Control UI is the primary production interface for the Alfred Agent Platform. It is built with Next.js and provides a comprehensive dashboard for managing agents, workflows, and monitoring.
   
   **Status**: Active  
   **Technology**: Next.js, React  
   **Owner**: UI Team  
   **Repository**: `/mission-control`
   
   ### Streamlit Chat UI
   
   The Streamlit Chat UI is a development and testing tool for the Alfred Agent Platform. It provides a simple chat interface for testing conversation flows and agent responses.
   
   **Status**: Development Only  
   **Technology**: Streamlit  
   **Owner**: Backend Team  
   **Repository**: `/ui/streamlit-chat`
   
   ## Integration Strategy
   
   Both UIs integrate with the Alfred Bot API, which provides a consistent interface for all UI components. The Mission Control UI will be enhanced to include chat functionality equivalent to the Streamlit Chat UI.
   
   ## Future Plans
   
   1. Enhance Mission Control UI with chat functionality
   2. Deprecate Streamlit Chat UI once Mission Control chat is complete
   3. Develop mobile app using the same API endpoints
   EOF
   ```

5. **Create Secrets Management Document**:
   ```bash
   # Create secrets management document
   mkdir -p docs/ops
   
   cat > docs/ops/secrets.md << 'EOF'
   # Secrets Management
   
   ## Overview
   
   This document outlines the secrets management strategy for the Alfred Agent Platform.
   
   ## Secret Storage
   
   | Environment | Storage | Access Method | Rotation |
   |-------------|---------|---------------|----------|
   | Development | .env file + .env.dev | Local file | Manual |
   | CI/CD | GitHub Actions Secrets | Repository secrets | Manual |
   | Staging | Fly.io secrets | fly secrets set | 30-day automated |
   | Production | Google Secret Manager | GKE workload identity | 30-day automated |
   
   ## Secret Rotation Schedule
   
   | Secret Type | Rotation Frequency | Responsible Team | Procedure |
   |-------------|-------------------|------------------|-----------|
   | Slack Tokens | 90 days | Platform Team | Manually rotate in Slack admin console |
   | API Keys (OpenAI, etc.) | 30 days | Security Team | Automated rotation via CI/CD |
   | Database Credentials | 90 days | DBA Team | Automated rotation script |
   | Service Tokens | 30 days | Security Team | Automated rotation via CI/CD |
   
   ## Required Secrets
   
   | Secret Name | Description | Example |
   |-------------|-------------|---------|
   | SLACK_BOT_TOKEN | OAuth token for Slack bot | xoxb-123... |
   | SLACK_SIGNING_SECRET | Signing secret for verifying Slack requests | a1b2c3... |
   | SLACK_APP_TOKEN | App-level token for Slack | xapp-123... |
   | DATABASE_URL | Supabase PostgreSQL connection string | postgresql://... |
   | SUPABASE_SERVICE_ROLE_KEY | Service role key for Supabase | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... |
   | REDIS_URL | Redis connection string | redis://redis:6379/0 |
   | RAG_URL | URL for RAG service | http://atlas-rag-gateway:8501 |
   | ALFRED_RAG_API_KEY | API key for RAG service | rag-key-123 |
   | OPENAI_API_KEY | API key for OpenAI | sk-... |
   EOF
   ```
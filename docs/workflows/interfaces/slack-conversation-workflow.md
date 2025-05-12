# Implementation Integration Plan

## Overview

This plan outlines how to properly integrate the enhanced Slack Bot, ngrok configuration, and Streamlit Chat UI with the existing Alfred Agent Platform infrastructure, ensuring compliance with project rules, documentation standards, and integration with central services.

## 1. Project Rules Compliance

### Code Style and Structure

- **Python Style**: Follow existing platform conventions
  - Use snake_case for variables/functions
  - Use PascalCase for classes
  - 4-space indentation
  - Maximum line length of 100 characters
  - Full type hints with mypy compatibility

- **Package Structure**: Match existing services
  ```
  services/alfred-bot/
  ├── app/
  │   ├── __init__.py
  │   ├── main.py             # Enhanced main file
  │   ├── api/                # API endpoints
  │   ├── adapters/           # Interface adapters
  │   └── utils/              # Helper functions
  ├── tests/
  │   ├── __init__.py
  │   ├── test_main.py
  │   └── test_api.py
  ├── Dockerfile
  ├── requirements.txt
  └── README.md
  ```

- **Testing Requirements**:
  - Minimum 70% code coverage
  - Unit tests for all functions
  - Integration tests for API endpoints
  - Use pytest with the same markers as existing tests

### Development Workflow

- **Git Workflow**:
  - Create feature branches from `develop`
  - Use branch naming: `feature/enhanced-slack-bot`
  - Follow commit message conventions:
    ```
    feat(slack-bot): add conversation capabilities
    
    - Add support for direct messages
    - Implement threaded conversations
    - Add rich message formatting
    ```

- **PR Process**:
  - Submit PRs to `develop` branch
  - Require at least one reviewer
  - Pass all CI/CD checks before merge
  - Include documentation updates in the same PR

## 2. Integration with Documentation System

### Linking with Existing Documentation

- Update relevant cross-references in:
  - `/docs/architecture/system-architecture.md` - Add Slack Bot to architecture diagram
  - `/docs/api/a2a-protocol.md` - Add Slack Bot intents
  - `/docs/IMPLEMENTATION_STATUS.md` - Update implementation status

### Versioning

- Update documentation metadata:
  ```
  **Last Updated:** [current date]
  **Version:** 2.0.0
  **Status:** Active
  ```

- Add changelog entries to documentation:
  ```
  ## Changelog
  | Version | Date | Changes |
  |---------|------|---------|
  | 2.0.0   | 2025-05-12 | Enhanced with conversation, threading, and Streamlit UI |
  | 1.0.0   | 2025-04-15 | Initial implementation |
  ```

### Doc Validation

- Run documentation validation scripts:
  ```bash
  cd /home/locotoki/projects/alfred-agent-platform-v2
  ./scripts/validate-doc.sh docs/agents/interfaces/alfred-slack-bot.md
  ./scripts/validate-doc.sh docs/workflows/interfaces/slack-conversation-workflow.md
  ./scripts/validate-doc.sh docs/interfaces/chat-ui-implementation.md
  ```

## 3. Integration with Central Services

### RAG Integration

The enhanced Slack Bot should integrate with the Atlas RAG service for improved contextual responses:

```python
# services/alfred-bot/app/adapters/rag_adapter.py
from typing import Dict, Any, List, Optional
import aiohttp
import os
import json

class RAGAdapter:
    """Adapter for the Atlas RAG service."""
    
    def __init__(self):
        self.rag_url = os.environ.get("RAG_URL", "http://atlas-rag-gateway:8501")
        self.api_key = os.environ.get("ALFRED_RAG_API_KEY", "alfred-key")
        self.collection = os.environ.get("ALFRED_PERSONAL_COLLECTION", "alfred-personal")
    
    async def query(self, query_text: str, context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Query the RAG service for relevant information."""
        headers = {
            "Content-Type": "application/json",
            "X-API-Key": self.api_key
        }
        
        payload = {
            "query": query_text,
            "collection": self.collection,
            "top_k": int(os.environ.get("RAG_TOP_K", "15")),
            "context": context or {}
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.rag_url}/api/query", 
                headers=headers, 
                json=payload
            ) as response:
                if response.status == 200:
                    return await response.json()
                else:
                    error_text = await response.text()
                    raise Exception(f"RAG query failed: {error_text}")

    async def enrich_message(self, message: str, context: Dict[str, Any]) -> Dict[str, Any]:
        """Enrich user message with relevant context from RAG."""
        try:
            rag_response = await self.query(message, context)
            
            # Extract relevant documents
            documents = rag_response.get("documents", [])
            
            # Format context from documents
            formatted_context = "\n\n".join([
                f"Document: {doc.get('metadata', {}).get('source', 'Unknown')}\n"
                f"Content: {doc.get('content', 'No content')}"
                for doc in documents
            ])
            
            return {
                "enriched_message": message,
                "context": formatted_context,
                "relevance_score": rag_response.get("relevance_score", 0.0)
            }
        except Exception as e:
            # Fail gracefully on RAG errors
            return {
                "enriched_message": message,
                "context": "",
                "relevance_score": 0.0,
                "error": str(e)
            }
```

Usage in conversation handler:

```python
# Add to services/alfred-bot/app/main.py
from app.adapters.rag_adapter import RAGAdapter

# Initialize RAG adapter
rag_adapter = RAGAdapter()

async def handle_conversation(client, channel_id, user_id, message, thread_ts=None):
    """Handle a conversation message with Alfred."""
    try:
        # Enrich message with RAG context
        context = {"user_id": user_id, "channel_id": channel_id}
        enriched = await rag_adapter.enrich_message(message, context)
        
        # Use enriched context for better responses
        if enriched["relevance_score"] > float(os.environ.get("RELEVANCY_THRESHOLD", "0.65")):
            # Use the context in the response
            response_text = f"Based on what I know: {message}\n\nContext: {enriched['context']}"
        else:
            # Fallback to simple response
            response_text = f"I received your message: '{message}'"
        
        # Send the response to Slack
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text=response_text
        )
    except Exception as e:
        logger.error("conversation_failed", error=str(e))
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="Sorry, I'm having trouble processing your message. Please try again."
        )
```

### Agent-to-Agent (A2A) Protocol

Ensure all communication with other agents follows the A2A protocol:

```python
# Example of A2A integration for trend analysis
async def handle_trend_analysis(client, channel_id, user_id, query, thread_ts=None):
    """Handle trend analysis command."""
    if not query:
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="Please provide a trend to analyze. Example: `trend artificial intelligence`"
        )
        return

    # Create envelope following A2A protocol standards
    envelope = A2AEnvelope(
        intent="TREND_ANALYSIS",
        content={
            "query": query,
            "user_id": user_id,
            "channel_id": channel_id,
            "thread_ts": thread_ts,
            "interface": "slack"
        },
        metadata={
            "priority": "normal",
            "timeout_seconds": 60,
            "originating_service": "alfred-bot"
        }
    )

    try:
        # Store task in Supabase
        task_id = await supabase_transport.store_task(envelope)
        
        # Publish task to Pub/Sub
        message_id = await pubsub_transport.publish_task(envelope)
        
        # Acknowledge the request
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text=f"Analyzing trends for: *{query}*\nTask ID: `{envelope.task_id}`"
        )
    except Exception as e:
        logger.error("trend_analysis_failed", error=str(e))
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="Failed to start trend analysis. Please try again."
        )
```

## 4. Integration with Existing Storage

### Supabase Integration

Leverage existing Supabase infrastructure for storing task and conversation data:

```python
# services/alfred-bot/app/adapters/supabase_adapter.py
from typing import Dict, Any, List, Optional
import os
import json
from datetime import datetime, timezone
from supabase import create_client, Client

class SupabaseAdapter:
    """Adapter for Supabase database operations."""
    
    def __init__(self):
        self.url = os.environ.get("SUPABASE_URL")
        self.key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
        self.client = create_client(self.url, self.key)
    
    async def store_conversation(self, user_id: str, message: str, response: str, metadata: Dict[str, Any]) -> str:
        """Store a conversation entry in Supabase."""
        conversation_data = {
            "user_id": user_id,
            "message": message,
            "response": response,
            "metadata": json.dumps(metadata),
            "created_at": datetime.now(timezone.utc).isoformat(),
            "interface": "slack"
        }
        
        result = self.client.table("conversations").insert(conversation_data).execute()
        return result.data[0]["id"] if result.data else None
    
    async def get_user_history(self, user_id: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Get conversation history for a specific user."""
        result = self.client.table("conversations") \
            .select("*") \
            .eq("user_id", user_id) \
            .order("created_at", desc=True) \
            .limit(limit) \
            .execute()
        
        return result.data
```

### Redis Integration

Use Redis for caching and temporary data:

```python
# services/alfred-bot/app/adapters/redis_adapter.py
from typing import Dict, Any, Optional, List, Union
import redis.asyncio as redis
import os
import json
import time

class RedisAdapter:
    """Adapter for Redis operations."""
    
    def __init__(self):
        self.redis = redis.from_url(os.environ.get("REDIS_URL", "redis://redis:6379/0"))
        self.default_ttl = 3600  # 1 hour
    
    async def set_conversation_state(self, user_id: str, state: Dict[str, Any], ttl: int = None) -> bool:
        """Store conversation state in Redis."""
        key = f"conversation:{user_id}"
        return await self.redis.set(
            key, 
            json.dumps(state), 
            ex=ttl or self.default_ttl
        )
    
    async def get_conversation_state(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get conversation state from Redis."""
        key = f"conversation:{user_id}"
        data = await self.redis.get(key)
        if data:
            return json.loads(data)
        return None
    
    async def add_to_rate_limit(self, user_id: str, command: str) -> int:
        """Add to rate limit counter for a user and command."""
        key = f"rate_limit:{user_id}:{command}"
        # Get the current minute timestamp for bucketing
        minute_bucket = int(time.time() / 60) * 60
        field = str(minute_bucket)
        
        # Increment the counter for this minute
        count = await self.redis.hincrby(key, field, 1)
        
        # Set expiry to 10 minutes if not already set
        if count == 1:
            await self.redis.expire(key, 600)
        
        return count
    
    async def get_rate_limit_count(self, user_id: str, command: str) -> int:
        """Get the current rate limit count for a user and command."""
        key = f"rate_limit:{user_id}:{command}"
        minute_bucket = int(time.time() / 60) * 60
        field = str(minute_bucket)
        
        count = await self.redis.hget(key, field)
        return int(count) if count else 0
```

## 5. Environment Variables

Add the following environment variables to the `.env` file for integration with existing services:

```bash
# Slack Integration
SLACK_BOT_TOKEN=xoxb-your-slack-bot-token
SLACK_SIGNING_SECRET=your-slack-signing-secret
SLACK_APP_TOKEN=xapp-your-slack-app-token

# RAG Integration
RAG_URL=http://atlas-rag-gateway:8501
ALFRED_RAG_API_KEY=alfred-key
ALFRED_PERSONAL_COLLECTION=alfred-personal
RAG_TOP_K=15
RELEVANCY_THRESHOLD=0.65

# Storage
SUPABASE_URL=http://supabase-rest:3000
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
REDIS_URL=redis://redis:6379/0
DATABASE_URL=postgresql://postgres:password@supabase-db:5432/postgres

# A2A Communication
GCP_PROJECT_ID=alfred-agent-platform
PUBSUB_EMULATOR_HOST=pubsub-emulator:8085

# HTTP Tunneling
NGROK_AUTHTOKEN=your-ngrok-authtoken
VERIFY_TOKEN=your-verification-token

# System Settings
LOG_LEVEL=INFO
ENVIRONMENT=development
DEBUG=true
```

## 6. Docker Integration

Update the Docker Compose configuration to include the enhanced services:

```yaml
# Add to docker-compose.yml
services:
  # Enhanced Alfred Bot
  alfred-bot:
    build:
      context: ./services/alfred-bot
      dockerfile: Dockerfile
    container_name: alfred-bot
    depends_on:
      supabase-db:
        condition: service_healthy
      pubsub-emulator:
        condition: service_started
      redis:
        condition: service_started
      atlas-rag-gateway:
        condition: service_started
    ports:
      - "8011:8011"
    environment:
      - ENVIRONMENT=${ENVIRONMENT:-development}
      - DEBUG=${DEBUG:-true}
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=redis://redis:6379
      - PUBSUB_EMULATOR_HOST=pubsub-emulator:8085
      - GCP_PROJECT_ID=${GCP_PROJECT_ID:-alfred-agent-platform}
      - SLACK_BOT_TOKEN=${SLACK_BOT_TOKEN}
      - SLACK_SIGNING_SECRET=${SLACK_SIGNING_SECRET}
      - SLACK_APP_TOKEN=${SLACK_APP_TOKEN}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - RAG_URL=${RAG_URL:-http://atlas-rag-gateway:8501}
      - ALFRED_RAG_API_KEY=${ALFRED_RAG_API_KEY:-alfred-key}
      - ALFRED_PERSONAL_COLLECTION=${ALFRED_PERSONAL_COLLECTION:-alfred-personal}
      - RAG_TOP_K=${RAG_TOP_K:-15}
      - RELEVANCY_THRESHOLD=${RELEVANCY_THRESHOLD:-0.65}
      - SUPABASE_URL=${SUPABASE_URL}
      - SUPABASE_SERVICE_ROLE_KEY=${SUPABASE_SERVICE_ROLE_KEY}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8011/health/"]
      interval: 30s
      timeout: 10s
      retries: 3
    volumes:
      - ./libs:/app/libs

  # Streamlit Chat UI
  streamlit-chat:
    build:
      context: ./services/streamlit-chat
      dockerfile: Dockerfile
    container_name: streamlit-chat
    ports:
      - "8501:8501"
    environment:
      - ALFRED_API_URL=http://alfred-bot:8011
    depends_on:
      - alfred-bot
```

## 7. CI/CD Integration

Add GitHub Actions workflows for the new components:

```yaml
# .github/workflows/slack-bot-ci.yml
name: Slack Bot CI

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'services/alfred-bot/**'
  pull_request:
    branches: [ main ]
    paths:
      - 'services/alfred-bot/**'

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install flake8 black isort mypy
          pip install -r services/alfred-bot/requirements.txt
      - name: Lint with flake8
        run: flake8 services/alfred-bot
      - name: Check formatting with black
        run: black --check services/alfred-bot
      - name: Check imports with isort
        run: isort --check-only services/alfred-bot
      - name: Type check with mypy
        run: mypy services/alfred-bot

  test:
    runs-on: ubuntu-latest
    services:
      redis:
        image: redis
        ports:
          - 6379:6379
      
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install pytest pytest-asyncio pytest-cov
          pip install -r services/alfred-bot/requirements.txt
      - name: Test with pytest
        run: |
          cd services/alfred-bot
          python -m pytest --cov=app tests/
```

## 8. Monitoring and Observability

Integrate with the existing monitoring stack:

```python
# services/alfred-bot/app/utils/metrics.py
from prometheus_client import Counter, Histogram, Gauge
import time

# Define metrics
REQUESTS_COUNTER = Counter(
    'alfred_bot_requests_total', 
    'Total number of requests processed',
    ['method', 'endpoint', 'status']
)

RESPONSE_TIME = Histogram(
    'alfred_bot_response_time_seconds',
    'Response time in seconds',
    ['method', 'endpoint']
)

ACTIVE_USERS = Gauge(
    'alfred_bot_active_users',
    'Number of active users in the last 5 minutes'
)

class MetricsMiddleware:
    """Middleware for collecting metrics."""
    
    async def __call__(self, request, call_next):
        start_time = time.time()
        
        try:
            response = await call_next(request)
            status = response.status_code
        except Exception as e:
            status = 500
            raise e
        finally:
            duration = time.time() - start_time
            REQUESTS_COUNTER.labels(
                method=request.method,
                endpoint=request.url.path,
                status=status
            ).inc()
            
            RESPONSE_TIME.labels(
                method=request.method,
                endpoint=request.url.path
            ).observe(duration)
        
        return response
```

Add to FastAPI app:

```python
# Add to main.py
from app.utils.metrics import MetricsMiddleware
from prometheus_client import make_asgi_app

# Add Prometheus metrics endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

# Add metrics middleware
app.add_middleware(MetricsMiddleware)
```

## 9. Testing Strategy

Implement comprehensive testing that follows project standards:

```python
# services/alfred-bot/tests/test_main.py
import pytest
from unittest.mock import AsyncMock, patch
from fastapi.testclient import TestClient
from app.main import app

@pytest.fixture
def test_client():
    return TestClient(app)

@pytest.fixture
def mock_slack_client():
    with patch("app.main.slack_app") as mock_app:
        mock_app.client = AsyncMock()
        yield mock_app

@pytest.mark.asyncio
async def test_handle_ping(mock_slack_client):
    """Test the ping command handler."""
    # Setup mocks
    mock_client = AsyncMock()
    mock_client.chat_postMessage = AsyncMock()
    
    # Call the function
    from app.main import handle_ping
    await handle_ping(mock_client, "C123456", "U123456")
    
    # Verify the result
    mock_client.chat_postMessage.assert_called_once()
    args, kwargs = mock_client.chat_postMessage.call_args
    assert kwargs["channel"] == "C123456"
    assert "Ping task created" in kwargs["text"]

@pytest.mark.asyncio
async def test_handle_conversation(mock_slack_client):
    """Test the conversation handler."""
    # Setup mocks
    mock_client = AsyncMock()
    mock_client.chat_postMessage = AsyncMock()
    
    # Call the function
    from app.main import handle_conversation
    await handle_conversation(mock_client, "C123456", "U123456", "Hello Alfred")
    
    # Verify the result
    mock_client.chat_postMessage.assert_called_once()
    args, kwargs = mock_client.chat_postMessage.call_args
    assert kwargs["channel"] == "C123456"
    assert isinstance(kwargs["text"], str)
```

## 10. Deployment Steps

Follow these steps to deploy the integrated solution:

1. **Update code with integration changes**:
   ```bash
   cd /home/locotoki/projects/alfred-agent-platform-v2
   # Create feature branch
   git checkout -b feature/enhanced-slack-bot
   
   # Apply the integration changes
   cp -r /home/locotoki/enhanced_slack_bot.py services/alfred-bot/app/main.py
   # Add additional integration code as outlined above
   
   # Update documentation
   mkdir -p docs/agents/interfaces
   cp /home/locotoki/projects/alfred-agent-platform-v2/docs/agents/interfaces/alfred-slack-bot.md docs/agents/interfaces/
   mkdir -p docs/workflows/interfaces
   cp /home/locotoki/projects/alfred-agent-platform-v2/docs/workflows/interfaces/slack-conversation-workflow.md docs/workflows/interfaces/
   mkdir -p docs/interfaces
   cp /home/locotoki/projects/alfred-agent-platform-v2/docs/interfaces/chat-ui-implementation.md docs/interfaces/
   mkdir -p docs/integrations
   cp /home/locotoki/projects/alfred-agent-platform-v2/docs/integrations/ngrok-configuration.md docs/integrations/
   ```

2. **Update environmental configuration**:
   ```bash
   # Add required variables to .env
   cat >> .env << 'EOF'
   # Slack Integration
   SLACK_BOT_TOKEN=xoxb-your-slack-bot-token
   SLACK_SIGNING_SECRET=your-slack-signing-secret
   SLACK_APP_TOKEN=xapp-your-slack-app-token
   # RAG Integration
   RAG_URL=http://atlas-rag-gateway:8501
   ALFRED_RAG_API_KEY=alfred-key
   ALFRED_PERSONAL_COLLECTION=alfred-personal
   EOF
   ```

3. **Build and test locally**:
   ```bash
   # Build the services
   docker-compose build alfred-bot streamlit-chat
   
   # Run the services
   docker-compose up -d alfred-bot streamlit-chat
   
   # Check logs
   docker-compose logs -f alfred-bot streamlit-chat
   ```

4. **Set up ngrok**:
   ```bash
   sudo bash /home/locotoki/install-ngrok.sh
   # Add your auth token
   sudo sed -i 's/YOUR_NGROK_AUTH_TOKEN/your-actual-token/' /home/[username]/ngrok-alfred.yml
   sudo systemctl enable ngrok-alfred
   sudo systemctl start ngrok-alfred
   
   # Get your public URL
   curl http://localhost:4040/api/tunnels | jq '.tunnels[0].public_url'
   ```

5. **Update Slack App configuration**:
   - Go to https://api.slack.com/apps
   - Select your application
   - Update Event Subscriptions URL with your ngrok URL
   - Update Slash Commands URL with your ngrok URL

6. **Run tests**:
   ```bash
   cd services/alfred-bot
   python -m pytest --cov=app tests/
   ```

7. **Commit changes**:
   ```bash
   git add .
   git commit -m "feat(slack-bot): add conversation capabilities and UI integration
   
   - Add support for direct messages
   - Implement threaded conversations
   - Add RAG integration for context-aware responses
   - Add Streamlit Chat UI
   - Configure ngrok for webhook exposure
   - Add comprehensive documentation"
   ```

8. **Create PR**:
   - Push the branch to GitHub
   - Create a PR to `develop` branch
   - Ensure all CI checks pass
   - Request reviews from relevant team members

## 11. Post-Deployment Verification

After deploying, verify the integration with existing systems:

1. **Verify Slack Integration**:
   - Test the `/alfred` slash command
   - Test direct messaging
   - Test threaded conversations
   - Verify responses are enriched with RAG content

2. **Verify Streamlit UI**:
   - Access the UI at http://localhost:8501
   - Test conversational capabilities
   - Verify API communication with Alfred Bot

3. **Check Monitoring**:
   - Access Prometheus metrics at http://localhost:8011/metrics
   - Check Grafana for the new metrics
   - Verify logs are being properly formatted and stored

4. **Validate Storage**:
   - Check Supabase for conversation records
   - Verify Redis caching is working correctly

5. **Performance Testing**:
   - Test response times under load
   - Verify RAG query performance
   - Check rate limiting effectiveness
# Slack Integration Developer Guide

## Creating a New Agent

This guide walks you through creating a new agent that processes Slack commands through the Redis stream architecture.

### Agent Template

```python
#!/usr/bin/env python3
"""Template for creating a new Slack command agent."""

import json
import logging
import os
import sys
import time
import uuid
from typing import Any, Dict, Optional

import redis
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

class MyAgent:
    def __init__(self):
        # Redis connection
        self.redis_url = os.environ.get("REDIS_URL", "redis://localhost:6379")
        self.redis_client = None

        # Slack client (optional, for rich interactions)
        self.slack_token = os.environ.get("SLACK_BOT_TOKEN")
        self.slack_client = WebClient(token=self.slack_token) if self.slack_token else None

        # Stream configuration
        self.request_stream = "mcp.requests"
        self.response_stream = "mcp.responses"
        self.consumer_group = "my-agent"  # Change this!
        self.consumer_name = f"my-agent-{uuid.uuid4().hex[:8]}"

    def connect(self):
        """Establish connections to Redis and validate setup."""
        try:
            # Connect to Redis
            self.redis_client = redis.from_url(self.redis_url, decode_responses=True)
            self.redis_client.ping()
            logger.info("Connected to Redis")

            # Ensure consumer group exists
            try:
                self.redis_client.xgroup_create(
                    self.request_stream,
                    self.consumer_group,
                    id="0",
                    mkstream=True
                )
                logger.info(f"Created consumer group {self.consumer_group}")
            except redis.ResponseError as e:
                if "BUSYGROUP" in str(e):
                    logger.info(f"Consumer group {self.consumer_group} already exists")
                else:
                    raise

        except Exception as e:
            logger.error(f"Failed to connect: {e}")
            sys.exit(1)

    def should_process(self, request_data: Dict[str, Any]) -> bool:
        """Determine if this agent should process the request."""
        text = request_data.get("text", "").strip().lower()

        # Example: Process commands starting with "analyze"
        return text.startswith("analyze")

    def process_command(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """Process the command and generate a response."""
        text = request_data.get("text", "").strip()
        user_id = request_data.get("user_id")
        channel_id = request_data.get("channel_id")

        # Parse command
        parts = text.split(maxsplit=1)
        command = parts[0].lower()
        args = parts[1] if len(parts) > 1 else ""

        # Example command handling
        if command == "analyze":
            if not args:
                return self._error_response(request_data, "Please provide text to analyze")

            # Your analysis logic here
            word_count = len(args.split())
            char_count = len(args)

            response_text = (
                f"📊 Analysis Results:\\n"
                f"• Words: {word_count}\\n"
                f"• Characters: {char_count}\\n"
                f"• User: <@{user_id}>"
            )

            return {
                "request_id": request_data.get("id"),
                "text": response_text,
                "channel_id": channel_id,  # Optional: for thread support
            }

        return self._error_response(request_data, f"Unknown command: {command}")

    def _error_response(self, request_data: Dict[str, Any], error_msg: str) -> Dict[str, Any]:
        """Generate an error response."""
        return {
            "request_id": request_data.get("id"),
            "text": f"❌ {error_msg}",
        }

    def send_rich_response(self, channel_id: str, blocks: list):
        """Send a rich Slack message with blocks (optional)."""
        if not self.slack_client:
            logger.warning("Slack client not configured for rich responses")
            return

        try:
            self.slack_client.chat_postMessage(
                channel=channel_id,
                blocks=blocks
            )
        except SlackApiError as e:
            logger.error(f"Slack API error: {e}")

    def run(self):
        """Main agent loop."""
        self.connect()
        logger.info(f"Agent ready: {self.consumer_name}")

        while True:
            try:
                # Read messages from stream
                messages = self.redis_client.xreadgroup(
                    self.consumer_group,
                    self.consumer_name,
                    {self.request_stream: ">"},
                    count=1,
                    block=5000  # 5 second timeout
                )

                if not messages:
                    continue

                # Process each message
                for stream_name, stream_messages in messages:
                    for message_id, fields in stream_messages:
                        try:
                            # Parse request
                            if "data" in fields:
                                request_data = json.loads(fields["data"])
                            else:
                                request_data = fields

                            # Check if we should process this
                            if not self.should_process(request_data):
                                logger.debug(f"Skipping non-matching command: {request_data.get('text')}")
                                # Acknowledge to prevent reprocessing
                                self.redis_client.xack(
                                    self.request_stream,
                                    self.consumer_group,
                                    message_id
                                )
                                continue

                            logger.info(f"Processing: {request_data.get('text')}")

                            # Process command
                            response = self.process_command(request_data)

                            # Publish response
                            response_json = json.dumps(response)
                            self.redis_client.xadd(
                                self.response_stream,
                                {"data": response_json}
                            )

                            logger.info(f"Published response for {response['request_id']}")

                        except Exception as e:
                            logger.error(f"Error processing message {message_id}: {e}")
                        finally:
                            # Always acknowledge to prevent stuck messages
                            self.redis_client.xack(
                                self.request_stream,
                                self.consumer_group,
                                message_id
                            )

            except KeyboardInterrupt:
                logger.info("Shutting down...")
                break
            except Exception as e:
                logger.error(f"Unexpected error: {e}")
                time.sleep(5)

if __name__ == "__main__":
    agent = MyAgent()
    agent.run()
```

### Docker Configuration

```yaml
# docker-compose.override.yml
services:
  my-agent:
    image: python:3.11-slim
    container_name: my-agent
    working_dir: /app
    command: >
      bash -c "pip install redis slack-sdk &&
      python /app/services/my_agent/agent.py"
    environment:
      - REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379
      - SLACK_BOT_TOKEN=${SLACK_BOT_TOKEN}  # Optional
      - LOG_LEVEL=INFO
    volumes:
      - ./services/my_agent:/app/services/my_agent
    depends_on:
      - redis
      - slack_mcp_gateway
    restart: unless-stopped
    networks:
      - alfred-network
```

## Advanced Patterns

### 1. Command Router Pattern

For complex command hierarchies:

```python
class CommandRouter:
    def __init__(self):
        self.handlers = {
            "analyze": self.handle_analyze,
            "report": self.handle_report,
            "help": self.handle_help,
        }

    def route(self, request_data):
        text = request_data.get("text", "").strip()
        command = text.split()[0].lower() if text else "help"

        handler = self.handlers.get(command, self.handle_unknown)
        return handler(request_data)

    def handle_analyze(self, request_data):
        # Implementation
        pass
```

### 2. Async Processing Pattern

For long-running tasks:

```python
def process_command(self, request_data):
    # Send immediate acknowledgment
    self.publish_response({
        "request_id": request_data.get("id"),
        "text": "⏳ Processing your request...",
        "ephemeral": True  # Only visible to user
    })

    # Start async task
    task_id = self.start_async_task(request_data)

    # Return task started message
    return {
        "request_id": request_data.get("id"),
        "text": f"Task started: {task_id}. I'll notify you when complete.",
    }
```

### 3. Conversation State Pattern

For multi-turn interactions:

```python
class StatefulAgent:
    def __init__(self):
        # Use Redis for conversation state
        self.state_ttl = 3600  # 1 hour

    def get_conversation_state(self, user_id: str) -> dict:
        state_key = f"conversation:{user_id}"
        state = self.redis_client.get(state_key)
        return json.loads(state) if state else {}

    def set_conversation_state(self, user_id: str, state: dict):
        state_key = f"conversation:{user_id}"
        self.redis_client.setex(
            state_key,
            self.state_ttl,
            json.dumps(state)
        )

    def process_command(self, request_data):
        user_id = request_data.get("user_id")
        state = self.get_conversation_state(user_id)

        # Process based on state
        if state.get("awaiting_confirmation"):
            return self.handle_confirmation(request_data, state)
        else:
            return self.handle_new_command(request_data)
```

### 4. Rich Message Pattern

Using Slack Block Kit:

```python
def create_rich_response(self, data):
    blocks = [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "📊 Analysis Results"
            }
        },
        {
            "type": "section",
            "fields": [
                {
                    "type": "mrkdwn",
                    "text": f"*Total:*\\n{data['total']}"
                },
                {
                    "type": "mrkdwn",
                    "text": f"*Average:*\\n{data['average']}"
                }
            ]
        },
        {
            "type": "actions",
            "elements": [
                {
                    "type": "button",
                    "text": {"type": "plain_text", "text": "Export"},
                    "value": "export",
                    "action_id": "export_results"
                }
            ]
        }
    ]

    return {
        "request_id": request_data.get("id"),
        "blocks": json.dumps(blocks),
        "text": "Analysis complete"  # Fallback
    }
```

## Testing Your Agent

### Unit Tests

```python
# tests/test_my_agent.py
import pytest
from unittest.mock import Mock, patch
from services.my_agent.agent import MyAgent

class TestMyAgent:
    @pytest.fixture
    def agent(self):
        with patch('redis.from_url'):
            agent = MyAgent()
            agent.redis_client = Mock()
            return agent

    def test_should_process(self, agent):
        # Should process analyze commands
        assert agent.should_process({"text": "analyze this text"})
        assert agent.should_process({"text": "ANALYZE data"})

        # Should not process other commands
        assert not agent.should_process({"text": "help"})
        assert not agent.should_process({"text": ""})

    def test_process_analyze_command(self, agent):
        request = {
            "id": "test-123",
            "text": "analyze hello world",
            "user_id": "U123",
            "channel_id": "C123"
        }

        response = agent.process_command(request)

        assert response["request_id"] == "test-123"
        assert "Words: 2" in response["text"]
        assert "Characters: 11" in response["text"]
```

### Integration Tests

```python
# tests/test_integration.py
def test_end_to_end_flow():
    # Send test command
    redis_client.xadd("mcp.requests", {
        "id": "test-123",
        "text": "analyze integration test",
        "user_id": "U123",
        "channel_id": "C123"
    })

    # Wait for response
    time.sleep(1)

    # Check response
    messages = redis_client.xrange("mcp.responses", "-", "+")
    assert len(messages) > 0

    response = json.loads(messages[-1][1]["data"])
    assert response["request_id"] == "test-123"
    assert "Words: 2" in response["text"]
```

### Local Testing

```bash
# Test directly without Docker
export REDIS_URL=redis://localhost:6379
export SLACK_BOT_TOKEN=xoxb-test-token
python services/my_agent/agent.py

# In another terminal, send test message
redis-cli XADD mcp.requests '*' \
  id test-local \
  text "analyze local test" \
  user_id U123 \
  channel_id C123
```

## Best Practices

### 1. Error Handling
- Always acknowledge messages, even on error
- Log errors with context
- Return user-friendly error messages
- Use try-finally for acknowledgments

### 2. Performance
- Process one message at a time initially
- Use consumer groups for scaling
- Implement timeouts for external calls
- Monitor memory usage

### 3. Security
- Validate all inputs
- Sanitize output for Slack
- Use environment variables for secrets
- Implement rate limiting if needed

### 4. Monitoring
- Log all command processing
- Track processing time
- Monitor queue depths
- Alert on repeated failures

### 5. User Experience
- Respond quickly (even if just acknowledging)
- Use clear, actionable error messages
- Provide help/usage information
- Use emoji for visual clarity

## Debugging Tips

### Enable Debug Logging
```python
logging.basicConfig(level=logging.DEBUG)

# Or via environment
LOG_LEVEL=DEBUG python agent.py
```

### Inspect Redis Streams
```bash
# View pending messages
redis-cli XPENDING mcp.requests my-agent

# Read specific message
redis-cli XRANGE mcp.requests 1234567890-0 1234567890-0

# Monitor in real-time
redis-cli --scan --pattern "mcp.*" | xargs -I{} redis-cli XLEN {}
```

### Test Without Slack
```python
# Create test harness
def test_local():
    agent = MyAgent()

    # Mock request
    request = {
        "id": "test-123",
        "text": "analyze test data",
        "user_id": "U123",
        "channel_id": "C123"
    }

    # Process
    response = agent.process_command(request)
    print(json.dumps(response, indent=2))

if __name__ == "__main__":
    test_local()
```

## Deployment Checklist

- [ ] Agent handles all expected commands
- [ ] Error handling for edge cases
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Docker image builds
- [ ] Environment variables documented
- [ ] Logging at appropriate levels
- [ ] Monitoring/alerts configured
- [ ] Documentation updated
- [ ] Code reviewed
- [ ] Security scan passed

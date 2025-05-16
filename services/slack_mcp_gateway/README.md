# Slack MCP Gateway

A Python-based microservice that connects Slack to the Mission Control Platform via Redis Streams.

## Features

- Socket Mode for secure Slack communication
- Slash commands forwarding to Redis Streams
- Response handling with thread updates
- Standardized message translation

## Architecture

The service consists of several components:

- **bolt_socket.py**: Handles Slack interactions using the Bolt SDK with Socket Mode
- **translator.py**: Converts Slack payloads to MCP task requests
- **redis_bus.py**: Manages Redis Streams communication for requests and responses
- **responder.py**: Background task that processes responses and updates Slack threads

## Slash Commands

Currently supported commands:

- `/ping` - Simple ping command that publishes to Redis

## Message Flow

1. User issues a slash command in Slack
2. bolt_socket.py acknowledges the command
3. translator.py formats the command into a standard task request
4. redis_bus.py publishes the request to the "mcp.requests" stream
5. Mission Control processes the request
6. redis_bus.py subscribes to the "mcp.responses" stream
7. responder.py updates the Slack thread with the response

## Environment Configuration

Required environment variables:

```
# Slack App Credentials
SLACK_BOT_TOKEN=xoxb-your-token
SLACK_SIGNING_SECRET=your-signing-secret
SLACK_APP_TOKEN=xapp-your-app-level-token

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0
```

## Development

### Setup with Poetry

```bash
# Install dependencies
poetry install

# Run tests
poetry run pytest
```

### Setup with pip

```bash
# Install dependencies
pip install -r requirements.txt

# Run tests
pytest
```

## Testing

Run the test suite to validate functionality:

```bash
pytest
```
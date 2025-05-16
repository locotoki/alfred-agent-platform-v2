# Slack MCP Gateway

A microservice that connects Slack to the Mission Control Platform via Redis pub/sub.

## Features

- Socket Mode for secure Slack communication
- Slash commands forwarding to Redis channel
- Health check endpoint for monitoring
- Containerized for easy deployment

## Slash Commands

Currently supported commands:

- `/ping` - Simple ping command that publishes to Redis

## Environment Configuration

Copy `.env.sample` to `.env` and fill in the required values:

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

# Application Configuration
PORT=3000
LOG_LEVEL=info
```

## Development

```bash
# Install dependencies
npm install

# Run in development mode
npm run dev
```

## Production

```bash
# Start the service
npm start
```

## Docker

```bash
# Build the Docker image
docker build -t slack-mcp-gateway .

# Run the Docker container
docker run -p 3000:3000 --env-file .env slack-mcp-gateway
```

## Redis Message Format

Messages published to the `slack:commands` channel have the following format:

```json
{
  "command": "ping",
  "user_id": "U12345678",
  "channel_id": "C12345678",
  "team_id": "T12345678",
  "text": "command text",
  "timestamp": "2023-06-01T12:00:00.000Z"
}
```
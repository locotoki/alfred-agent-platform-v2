# Slack Integration Quick Start Guide

## Prerequisites

1. **Slack App Setup**
   - Create a Slack app at https://api.slack.com/apps
   - Enable Socket Mode (Settings → Socket Mode)
   - Add Bot Token Scopes:
     - `commands` - Handle slash commands
     - `chat:write` - Send messages
     - `chat:write.public` - Send to channels without joining
   - Install app to workspace
   - Copy tokens:
     - **App-Level Token** (starts with `xapp-`)
     - **Bot User OAuth Token** (starts with `xoxb-`)

2. **Environment Variables**
   ```bash
   # .env file
   SLACK_APP_TOKEN=xapp-1-...
   SLACK_BOT_TOKEN=xoxb-...
   REDIS_PASSWORD=your-secure-password
   ```

## Quick Start

### 1. Start Core Services
```bash
# Start Redis, Slack Gateway, and Echo Agent
docker-compose up -d redis slack_mcp_gateway

# Verify services are healthy
docker-compose ps
```

### 2. Start Echo Agent
```bash
# The echo agent is configured in docker-compose.override.yml
docker-compose up -d echo-agent

# Check logs
docker logs echo-agent --tail 20
```

### 3. Test in Slack
```
/alfred health
# Response: ✅ Echo agent is healthy and responding to commands!

/alfred ping hello world
# Response: 🏓 hello world
```

## Service Health Checks

```bash
# Check gateway health
curl http://localhost:3010/health

# Check Redis
docker exec redis redis-cli -a $REDIS_PASSWORD ping

# Check message queue
docker exec redis redis-cli -a $REDIS_PASSWORD XLEN mcp.requests
```

## Troubleshooting Checklist

### ❌ No Response in Slack

1. **Check Gateway Connection**
   ```bash
   docker logs slack_mcp_gateway | grep -E "Connected to Slack|Error"
   ```

2. **Verify Tokens**
   ```bash
   # Should see xapp- and xoxb- prefixes
   env | grep SLACK_ | cut -c1-20
   ```

3. **Check Redis Streams**
   ```bash
   # Are messages arriving?
   docker exec redis redis-cli -a $REDIS_PASSWORD XLEN mcp.requests

   # Check consumer groups
   docker exec redis redis-cli -a $REDIS_PASSWORD XINFO GROUPS mcp.requests
   ```

4. **Echo Agent Status**
   ```bash
   # Is it running?
   docker ps | grep echo-agent

   # Check logs
   docker logs echo-agent --tail 50
   ```

### ❌ "No metadata found for request"

This means the response arrived after metadata expired (1 hour TTL). Usually happens during development when debugging.

### ❌ Redis Connection Errors

```bash
# Test Redis auth
docker exec redis redis-cli -a $REDIS_PASSWORD INFO server

# If auth fails, check docker-compose.override.yml has:
# REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379
```

## Development Tips

### Send Test Message Directly
```bash
docker exec redis redis-cli -a $REDIS_PASSWORD \
  XADD mcp.requests '*' \
  id test-$(date +%s) \
  type slack_command \
  command /alfred \
  text "ping direct test" \
  user_id U123 \
  channel_id C123 \
  team_id T123
```

### Monitor Real-time Logs
```bash
# Watch all components
docker-compose logs -f slack_mcp_gateway echo-agent
```

### Reset Consumer Groups
```bash
# If messages are stuck
docker exec redis redis-cli -a $REDIS_PASSWORD \
  XGROUP DESTROY mcp.requests echo-agent

# Recreate will happen automatically
docker restart echo-agent
```

## Adding Your Own Agent

1. **Copy Echo Agent Template**
   ```bash
   cp services/slack_mcp_gateway/echo_agent.py services/my_agent/agent.py
   ```

2. **Modify Process Function**
   ```python
   def process_command(request_data):
       text = request_data.get("text", "")
       if text.startswith("my-command"):
           # Your logic here
           return {
               "request_id": request_data.get("id"),
               "text": "Your response"
           }
   ```

3. **Add to Docker Compose**
   ```yaml
   # docker-compose.override.yml
   my-agent:
     image: python:3.11-slim
     command: python /app/services/my_agent/agent.py
     environment:
       - REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379
     volumes:
       - ./services/my_agent:/app/services/my_agent
   ```

4. **Start Your Agent**
   ```bash
   docker-compose up -d my-agent
   ```

## Architecture Summary

```
Slack → slack_mcp_gateway → Redis(mcp.requests) → Agents
                               ↓
Slack ← slack_mcp_gateway ← Redis(mcp.responses) ← Agents
```

- **Gateway**: Bridges Slack ↔ Redis
- **Redis Streams**: Message queue (mcp.requests, mcp.responses)
- **Agents**: Process commands and return responses
- **Consumer Groups**: Ensure exactly-once processing

## Common Commands Reference

```bash
# Service Management
docker-compose up -d                    # Start all services
docker-compose down                     # Stop all services
docker-compose restart slack_mcp_gateway # Restart gateway

# Debugging
docker logs -f service_name             # Follow logs
docker exec -it service_name sh         # Shell into container

# Redis Commands
XLEN stream_name                        # Count messages
XRANGE stream_name - + COUNT 10         # View recent messages
XINFO GROUPS stream_name                # Check consumer groups
XGROUP DESTROY stream_name group_name   # Reset consumer group
```

## Security Notes

- Never commit tokens (use .env file)
- Redis password is required (no default)
- Dangerous Redis commands are disabled
- Use Socket Mode (no public webhooks)
- Bot needs channel invitation to respond

For detailed architecture and advanced topics, see [slack-integration-architecture.md](./slack-integration-architecture.md)

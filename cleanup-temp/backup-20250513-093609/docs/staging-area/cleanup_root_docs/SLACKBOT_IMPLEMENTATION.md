# Alfred Slack Bot Implementation Guide

This document outlines the implementation plan for the Alfred Slack Bot with ngrok integration for the Alfred Agent Platform v2.

## Current State

The Alfred Slack Bot is partially implemented with:

1. **Basic FastAPI Application**: The `/services/alfred-bot/app/main.py` contains a FastAPI application with Slack Bolt integration.
2. **Command Handling**: Implementation for basic slash commands like `/alfred help`, `/alfred ping`, and `/alfred trend`.
3. **Dockerfile**: Container definition is already set up with proper health checks.
4. **Requirements**: Necessary dependencies are defined in `requirements.txt`.
5. **Integration Documentation**: Guides for Slack and ngrok are available in documentation files.

However, there are several implementation gaps that need to be addressed:

1. **Direct Message Handling**: No implementation for processing direct messages to the bot.
2. **Conversation Threading**: No support for maintaining conversation threads.
3. **Rich Message Formatting**: Limited use of Slack's Block Kit.
4. **Event Subscription Handling**: Only slash commands are implemented, not mentions or messages.
5. **ngrok Integration**: No automated setup for ngrok during development.
6. **Error Handling**: Basic error handling needs enhancement.

## Implementation Plan

### 1. Enhance Slack Event Handling

Update `main.py` to handle additional event types:

```python
# Add these event handlers to main.py

@slack_app.event("message")
async def handle_message_events(body, logger, client, context):
    """Handle direct messages to the bot."""
    # Filter out bot messages to prevent loops
    if body.get("event", {}).get("bot_id"):
        return

    # Extract message details
    event = body["event"]
    user_id = event.get("user")
    channel_id = event.get("channel")
    text = event.get("text", "").strip()
    thread_ts = event.get("thread_ts")

    # Check if this is a DM channel
    is_dm = channel_id.startswith("D")

    # Process the message
    await process_message(client, channel_id, user_id, text, thread_ts, is_dm)

@slack_app.event("app_mention")
async def handle_mentions(body, logger, client, context):
    """Handle mentions of the bot in channels."""
    event = body["event"]
    user_id = event.get("user")
    channel_id = event.get("channel")
    text = event.get("text", "").strip()
    thread_ts = event.get("thread_ts")

    # Remove the bot mention from the text
    # Format is typically <@BOT_USER_ID> command args
    text = re.sub(r'<@[A-Z0-9]+>', '', text).strip()

    # Process the message
    await process_message(client, channel_id, user_id, text, thread_ts, False)

async def process_message(client, channel_id, user_id, text, thread_ts=None, is_dm=False):
    """Process a message from a user."""
    try:
        # For simplicity in direct messages, users don't need to type /alfred
        if is_dm and not text.startswith("/"):
            # Parse as command if it matches a command pattern
            parts = text.split(maxsplit=1)
            command = parts[0].lower() if parts else ""
            args = parts[1] if len(parts) > 1 else ""

            if command in ["help", "ping", "trend"]:
                # Handle as command
                if command == "help":
                    await show_help(client, channel_id, thread_ts)
                elif command == "ping":
                    await handle_ping(client, channel_id, user_id, thread_ts)
                elif command == "trend":
                    await handle_trend_analysis(client, channel_id, user_id, args, thread_ts)
            else:
                # Handle as chat message
                await handle_chat_message(client, channel_id, user_id, text, thread_ts)
        else:
            # In channels, require explicit command format
            if text.startswith("/alfred") or (is_dm and text.startswith("alfred")):
                # Strip prefix
                stripped_text = text.replace("/alfred", "").replace("alfred", "").strip()
                parts = stripped_text.split(maxsplit=1)
                command = parts[0].lower() if parts else ""
                args = parts[1] if len(parts) > 1 else ""

                # Handle commands
                if command == "help":
                    await show_help(client, channel_id, thread_ts)
                elif command == "ping":
                    await handle_ping(client, channel_id, user_id, thread_ts)
                elif command == "trend":
                    await handle_trend_analysis(client, channel_id, user_id, args, thread_ts)
                else:
                    await client.chat_postMessage(
                        channel=channel_id,
                        thread_ts=thread_ts,
                        text=f"Unknown command: {command}. Try `help` for available commands."
                    )
            else:
                # In a channel but not addressing the bot with a command
                pass

    except Exception as e:
        logger.error("message_processing_failed", error=str(e))
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="Sorry, something went wrong. Please try again later."
        )
```

### 2. Add Chat Message Handling

Implement a handler for general chat messages:

```python
async def handle_chat_message(client, channel_id, user_id, text, thread_ts=None):
    """Handle a general chat message to the bot."""
    # Create an A2A envelope for chat processing
    envelope = A2AEnvelope(
        intent="CHAT",
        content={
            "message": text,
            "user_id": user_id,
            "channel_id": channel_id,
            "thread_ts": thread_ts
        }
    )

    try:
        # Store and publish task
        await supabase_transport.store_task(envelope)
        await pubsub_transport.publish_task(envelope)

        # Send immediate acknowledgment
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="I'll get back to you in a moment..."
        )

        # In a real implementation, we would have a callback or webhook
        # that receives the response from the processing service

    except Exception as e:
        logger.error("chat_processing_failed", error=str(e))
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="Sorry, I couldn't process your message. Please try again."
        )
```

### 3. Update Command Handlers for Threads

Modify existing command handlers to support threads:

```python
# Update the existing handlers to include thread_ts parameter

async def handle_ping(client, channel_id, user_id, thread_ts=None):
    """Handle ping command."""
    # existing implementation with thread_ts added to client.chat_postMessage

async def handle_trend_analysis(client, channel_id, user_id, query, thread_ts=None):
    """Handle trend analysis command."""
    # existing implementation with thread_ts added to client.chat_postMessage

async def show_help(client, channel_id, thread_ts=None):
    """Show help message."""
    # existing implementation with thread_ts added to client.chat_postMessage
```

### 4. Implement Rich Message Formatting

Add support for Slack Block Kit:

```python
async def show_help(client, channel_id, thread_ts=None):
    """Show help message with rich formatting."""
    blocks = [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "Alfred Bot Commands",
                "emoji": True
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "I can help you with various tasks through slash commands or direct messages."
            }
        },
        {
            "type": "section",
            "fields": [
                {
                    "type": "mrkdwn",
                    "text": "*Basic Commands:*\n• `/alfred help` - Show this help message\n• `/alfred ping` - Test bot responsiveness"
                },
                {
                    "type": "mrkdwn",
                    "text": "*Intelligence:*\n• `/alfred trend <topic>` - Analyze trends for a topic"
                }
            ]
        },
        {
            "type": "section",
            "fields": [
                {
                    "type": "mrkdwn",
                    "text": "*Task Management:*\n• `/alfred status <task_id>` - Check task status\n• `/alfred cancel <task_id>` - Cancel a running task"
                }
            ]
        },
        {
            "type": "context",
            "elements": [
                {
                    "type": "mrkdwn",
                    "text": "💡 Tip: You can also send me direct messages without using the /alfred prefix!"
                }
            ]
        }
    ]

    await client.chat_postMessage(
        channel=channel_id,
        thread_ts=thread_ts,
        blocks=blocks,
        text="Alfred Bot Commands" # Fallback text for notifications
    )
```

### 5. Implement Task Response Handling

Add a webhook for receiving asynchronous task responses:

```python
@app.post("/api/task_response")
async def task_response(request: Request):
    """Handle task responses from other services."""
    data = await request.json()

    task_id = data.get("task_id")
    channel_id = data.get("channel_id")
    thread_ts = data.get("thread_ts")
    response = data.get("response")

    if not task_id or not channel_id or not response:
        return {"status": "error", "message": "Missing required fields"}

    try:
        # Retrieve task from database to get additional context if needed
        task = await supabase_transport.get_task(task_id)

        # Send the response to the user
        await slack_app.client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text=response.get("text", "Task completed"),
            blocks=response.get("blocks")
        )

        return {"status": "success"}
    except Exception as e:
        logger.error("task_response_failed", error=str(e), task_id=task_id)
        return {"status": "error", "message": str(e)}
```

### 6. Create ngrok Startup Script

Create a script for starting the Slack bot with ngrok:

```bash
#!/bin/bash
# start-slackbot-dev.sh

# Start ngrok in the background
echo "Starting ngrok..."
ngrok http 8011 > /dev/null &
NGROK_PID=$!

# Wait for ngrok to start
sleep 2

# Get ngrok URL
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
echo "ngrok URL: $NGROK_URL"
echo "Use this URL for Slack's Event Subscriptions: ${NGROK_URL}/slack/events"

# Print instructions
echo "---------------------------------------------------------------"
echo "1. Go to https://api.slack.com/apps"
echo "2. Select your Alfred bot app"
echo "3. Go to 'Event Subscriptions' and enable events"
echo "4. Set the Request URL to: ${NGROK_URL}/slack/events"
echo "5. Subscribe to bot events: message.im, app_mention"
echo "6. Go to 'Slash Commands' and update the /alfred command URL"
echo "7. Save changes"
echo "---------------------------------------------------------------"

# Start the bot
echo "Starting Alfred Slack Bot..."
cd ../.. # Assuming running from services/alfred-bot directory
python -m uvicorn services.alfred-bot.app.main:app --reload --host 0.0.0.0 --port 8011

# Clean up ngrok when the app is terminated
kill $NGROK_PID
```

### 7. Add Environment Variables Documentation

Add additional environment variables to the `.env` file with documentation:

```env
# Slack Bot Configuration
SLACK_BOT_TOKEN=xoxb-your-token-here
SLACK_SIGNING_SECRET=your-signing-secret-here
SLACK_APP_TOKEN=xapp-your-app-level-token-here  # For socket mode if needed

# Redis Configuration
REDIS_URL=redis://redis:6379

# Supabase Configuration
DATABASE_URL=postgresql://postgres:your-super-secret-password@supabase-db:5432/postgres
SUPABASE_URL=http://supabase-rest:3000
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# Google Cloud Configuration
GCP_PROJECT_ID=alfred-agent-platform
PUBSUB_EMULATOR_HOST=pubsub-emulator:8085
```

### 8. Update Docker Compose Configuration

Update the Alfred bot service in the Docker Compose file:

```yaml
alfred-bot:
  build:
    context: .
    dockerfile: services/alfred-bot/Dockerfile
  image: alfred-bot:latest
  container_name: alfred-agent-platform-v2-alfred-bot-1
  restart: unless-stopped
  depends_on:
    - redis
    - supabase-db
    - supabase-rest
    - pubsub-emulator
  environment:
    - SLACK_BOT_TOKEN=${SLACK_BOT_TOKEN}
    - SLACK_SIGNING_SECRET=${SLACK_SIGNING_SECRET}
    - SLACK_APP_TOKEN=${SLACK_APP_TOKEN}
    - REDIS_URL=redis://redis:6379
    - DATABASE_URL=${DATABASE_URL}
    - SUPABASE_URL=${SUPABASE_URL}
    - SUPABASE_SERVICE_ROLE_KEY=${SERVICE_ROLE_KEY}
    - GCP_PROJECT_ID=${GCP_PROJECT_ID}
    - PUBSUB_EMULATOR_HOST=${PUBSUB_EMULATOR_HOST}
  ports:
    - "8011:8011"
  networks:
    - alfred-network
  volumes:
    - ./services/alfred-bot:/app/services/alfred-bot
    - ./libs:/app/libs
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8011/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 5s
```

## Implementation Steps

Follow these steps to implement the Slack bot:

1. **Update Source Code**:
   - Update `main.py` with the enhanced event handling code
   - Implement rich message formatting for responses
   - Add the task response webhook

2. **Create Development Scripts**:
   - Create the `start-slackbot-dev.sh` script for local development
   - Make it executable: `chmod +x services/alfred-bot/start-slackbot-dev.sh`

3. **Configure Slack App**:
   - Go to https://api.slack.com/apps
   - Create a new app or select your Alfred bot app
   - Configure Event Subscriptions:
     - Enable events
     - Set the Request URL to your ngrok URL + `/slack/events`
     - Subscribe to bot events: `message.im`, `app_mention`
   - Configure Slash Commands:
     - Create a `/alfred` command with the same URL
   - Install the app to your workspace
   - Copy the Bot User OAuth Token and Signing Secret

4. **Set Environment Variables**:
   - Update the `.env` file with your Slack tokens and other configs

5. **Start the Bot for Development**:
   - Run `./services/alfred-bot/start-slackbot-dev.sh`
   - Verify the ngrok tunnel is working
   - Test the bot with slash commands and direct messages

6. **Test in Docker Environment**:
   - Build and start the Docker container: `docker-compose -f docker-compose.combined-fixed.yml up -d alfred-bot`
   - For public access, set up ngrok separately to tunnel to port 8011

## Testing

Test the following functionality:

1. **Slash Commands**:
   - `/alfred help` - Should show rich help message
   - `/alfred ping` - Should respond with acknowledgment
   - `/alfred trend AI` - Should acknowledge and promise a response

2. **Direct Messages**:
   - Send a direct message to the bot: "help"
   - Chat with the bot: "What can you do?"

3. **Mentions**:
   - In a channel, mention the bot: "@alfred help"
   - Try a trend analysis: "@alfred trend remote work"

4. **Error Handling**:
   - Test with invalid commands
   - Test with network disconnections
   - Test with rate limiting

## Resources

- [Slack API Documentation](https://api.slack.com/docs)
- [Slack Bolt Python Library](https://slack.dev/bolt-python/concepts)
- [ngrok Documentation](https://ngrok.com/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Slack Block Kit Builder](https://app.slack.com/block-kit-builder)

## Troubleshooting

Common issues and solutions:

1. **ngrok URL Not Working**:
   - Check if ngrok is running: `ps aux | grep ngrok`
   - Check the ngrok web interface: http://localhost:4040
   - Try restarting ngrok

2. **Slack Event Verification Failing**:
   - Verify your signing secret is correct
   - Check the request URL in Slack's configuration
   - Ensure your clock is synchronized (time skew can cause verification issues)

3. **Missing Bot Messages**:
   - Check bot token scopes in Slack API dashboard
   - Verify the bot is in the channel
   - Check if the bot needs to be invited to channels

4. **Command Not Recognized**:
   - Verify the command is registered in Slack API dashboard
   - Check the command URL in Slack's configuration
   - Test the command directly in the events test interface

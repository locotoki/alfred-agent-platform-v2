from fastapi import FastAPI, Request
from slack_bolt.adapter.fastapi import SlackRequestHandler
from slack_bolt import App
import os
import structlog
import redis
from contextlib import asynccontextmanager
import re
from datetime import datetime

from libs.a2a_adapter import A2AEnvelope, PubSubTransport, SupabaseTransport, PolicyMiddleware
from libs.agent_core.health import create_health_app

logger = structlog.get_logger(__name__)

# Initialize services
pubsub_transport = PubSubTransport(
    project_id=os.getenv("GCP_PROJECT_ID", "alfred-agent-platform")
)

supabase_transport = SupabaseTransport(
    database_url=os.getenv("DATABASE_URL")
)

redis_client = redis.from_url(os.getenv("REDIS_URL", "redis://redis:6379"))
policy_middleware = PolicyMiddleware(redis_client)

# Initialize Slack app
slack_app = App(
    token=os.environ.get("SLACK_BOT_TOKEN"),
    signing_secret=os.environ.get("SLACK_SIGNING_SECRET")
)

@slack_app.command("/alfred")
async def handle_alfred_command(ack, body, client):
    """Handle /alfred slash command."""
    await ack()

    try:
        command_text = body.get("text", "").strip()
        user_id = body["user_id"]
        channel_id = body["channel_id"]
        # Get thread_ts if command was sent in a thread
        thread_ts = body.get("thread_ts")

        # Parse command
        parts = command_text.split(maxsplit=1)
        if not parts:
            await client.chat_postMessage(
                channel=channel_id,
                thread_ts=thread_ts,
                text="Please specify a command. Try `/alfred help` for available commands."
            )
            return

        command = parts[0].lower()
        args = parts[1] if len(parts) > 1 else ""

        # Handle different commands
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
                text=f"Unknown command: {command}. Try `/alfred help` for available commands."
            )

    except Exception as e:
        logger.error("command_handling_failed", error=str(e))
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts if 'thread_ts' in locals() else None,
            text="Sorry, something went wrong. Please try again later."
        )

async def handle_ping(client, channel_id, user_id, thread_ts=None):
    """Handle ping command."""
    envelope = A2AEnvelope(
        intent="PING",
        content={
            "message": "ping",
            "user_id": user_id,
            "channel_id": channel_id,
            "thread_ts": thread_ts
        }
    )

    try:
        message_id = await pubsub_transport.publish_task(envelope)

        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text=f"Ping task created! Task ID: {envelope.task_id}"
        )
    except Exception as e:
        logger.error("ping_failed", error=str(e))
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="Failed to create ping task. Please try again."
        )

async def handle_trend_analysis(client, channel_id, user_id, query, thread_ts=None):
    """Handle trend analysis command."""
    if not query:
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="Please provide a trend to analyze. Example: `/alfred trend artificial intelligence`"
        )
        return

    envelope = A2AEnvelope(
        intent="TREND_ANALYSIS",
        content={
            "query": query,
            "user_id": user_id,
            "channel_id": channel_id,
            "thread_ts": thread_ts
        }
    )

    try:
        # Store task
        task_id = await supabase_transport.store_task(envelope)

        # Publish task
        message_id = await pubsub_transport.publish_task(envelope)

        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text=f"Analyzing trends for: {query}\nTask ID: {envelope.task_id}"
        )
    except Exception as e:
        logger.error("trend_analysis_failed", error=str(e))
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="Failed to start trend analysis. Please try again."
        )

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

# Create FastAPI app
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle."""
    # Startup
    await supabase_transport.connect()
    logger.info("alfred_bot_started")

    yield

    # Shutdown
    await supabase_transport.disconnect()
    logger.info("alfred_bot_stopped")

app = FastAPI(title="Alfred Bot", lifespan=lifespan)

# Add health check endpoints
health_app = create_health_app("alfred-bot", "1.0.0")
app.mount("/health", health_app)

# Add Slack handler
slack_handler = SlackRequestHandler(slack_app)

@app.post("/slack/events")
async def slack_events(request: Request):
    """Handle Slack events."""
    return await slack_handler.handle(request)

@slack_app.event("message")
async def handle_message_events(body, logger, client):
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

    # Process the message if it's a DM
    if is_dm:
        await process_message(client, channel_id, user_id, text, thread_ts, is_dm)

@slack_app.event("app_mention")
async def handle_mentions(body, logger, client):
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

@app.post("/api/chat")
async def chat(request: Request):
    """Handle chat requests from external interfaces like Streamlit."""
    data = await request.json()

    message = data.get("message")
    user_id = data.get("user_id", "streamlit_user")
    channel_id = data.get("channel_id", "streamlit_channel")
    thread_ts = data.get("thread_ts")

    if not message:
        return {"status": "error", "message": "Missing message field"}

    try:
        # Process the chat message - typically we'd call the same function that handles Slack messages
        # For simplicity and immediate response, we'll implement a synchronous response here

        parts = message.split(maxsplit=1)
        command = parts[0].lower() if parts else ""
        args = parts[1] if len(parts) > 1 else ""

        # Basic commands for quick responses
        if command == "help":
            return {
                "status": "success",
                "response": get_help_response_markdown()
            }
        elif command == "ping":
            return {
                "status": "success",
                "response": "Pong! Alfred is responsive. Task ID: chat-" + str(hash(message + str(datetime.now().timestamp())))[:8]
            }
        elif command == "trend" and args:
            # Create a task
            envelope = A2AEnvelope(
                intent="TREND_ANALYSIS",
                content={
                    "query": args,
                    "user_id": user_id,
                    "channel_id": channel_id,
                    "thread_ts": thread_ts
                }
            )

            # Store and publish the task
            await supabase_transport.store_task(envelope)
            await pubsub_transport.publish_task(envelope)

            return {
                "status": "success",
                "response": f"Analyzing trends for: {args}\nTask ID: {envelope.task_id}"
            }
        else:
            # General chat message - create a task for processing
            envelope = A2AEnvelope(
                intent="CHAT",
                content={
                    "message": message,
                    "user_id": user_id,
                    "channel_id": channel_id,
                    "thread_ts": thread_ts
                }
            )

            # Store and publish the task
            await supabase_transport.store_task(envelope)
            await pubsub_transport.publish_task(envelope)

            return {
                "status": "success",
                "response": "Your message is being processed. I'll respond shortly."
            }

    except Exception as e:
        logger.error("chat_api_failed", error=str(e))
        return {"status": "error", "message": f"Error processing message: {str(e)}"}


def get_help_response_markdown():
    """Get help response in markdown format."""
    return """
## Alfred Bot Commands

I can help you with various tasks through commands:

### Basic Commands:
- `help` - Show this help message
- `ping` - Test bot responsiveness

### Intelligence:
- `trend <topic>` - Analyze trends for a topic

### Task Management:
- `status <task_id>` - Check task status
- `cancel <task_id>` - Cancel a running task

You can also just chat with me naturally!
"""


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

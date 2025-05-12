from fastapi import FastAPI, Request, BackgroundTasks
from slack_bolt.adapter.fastapi import SlackRequestHandler
from slack_bolt import App
from slack_sdk.web import WebClient
import os
import structlog
import redis
import json
import time
import asyncio
from contextlib import asynccontextmanager
from pydantic import BaseModel
from typing import Optional, Dict, Any

# Setup logger
logger = structlog.get_logger(__name__)

# Initialize Slack app
slack_app = App(
    token=os.environ.get("SLACK_BOT_TOKEN"),
    signing_secret=os.environ.get("SLACK_SIGNING_SECRET")
)

# Redis for state management
redis_client = redis.from_url(os.environ.get("REDIS_URL", "redis://localhost:6379/0"))

# Models for API endpoints
class ChatRequest(BaseModel):
    message: str
    user_id: str
    channel_id: str
    thread_ts: Optional[str] = None

class AlfredResponse(BaseModel):
    response: str
    task_id: Optional[str] = None
    error: Optional[str] = None

# Handle direct messages to the bot
@slack_app.event("message")
async def handle_direct_messages(body, say, client):
    # Ignore messages from bots to prevent loops
    if body.get("event", {}).get("bot_id"):
        return
    
    event = body.get("event", {})
    channel_id = event.get("channel")
    user_id = event.get("user")
    text = event.get("text", "").strip()
    ts = event.get("ts")  # Message timestamp for threading
    
    try:
        # Check if it's a DM (direct message) channel
        channel_info = await client.conversations_info(channel=channel_id)
        is_dm = channel_info.get("channel", {}).get("is_im", False)
        
        if is_dm:
            # For DMs, directly process as commands without the /alfred prefix
            await process_message(text, user_id, channel_id, ts, say, client)
        else:
            # For regular channels, only respond to @mentions
            if f"<@{client.bot_user_id}>" in text:
                # Remove the mention from the text
                clean_text = text.replace(f"<@{client.bot_user_id}>", "").strip()
                await process_message(clean_text, user_id, channel_id, ts, say, client)
    except Exception as e:
        logger.error("event_handling_error", error=str(e), channel=channel_id, user=user_id)

async def process_message(text, user_id, channel_id, thread_ts, say, client):
    """Process an incoming message as a command or conversation."""
    try:
        # Check if it's a command (starting with a command word)
        command_words = ["help", "ping", "trend", "status", "cancel"]
        first_word = text.split()[0].lower() if text.split() else ""
        
        if first_word in command_words:
            # Process as a command
            command = first_word
            args = text[len(first_word):].strip()
            
            # Handle different commands
            if command == "help":
                await show_help(client, channel_id, thread_ts)
            elif command == "ping":
                await handle_ping(client, channel_id, user_id, thread_ts)
            elif command == "trend":
                await handle_trend_analysis(client, channel_id, user_id, args, thread_ts)
            elif command == "status":
                await handle_status(client, channel_id, user_id, args, thread_ts)
            elif command == "cancel":
                await handle_cancel(client, channel_id, user_id, args, thread_ts)
        else:
            # Process as a conversation with Alfred
            await handle_conversation(client, channel_id, user_id, text, thread_ts)
    
    except Exception as e:
        logger.error("message_processing_failed", error=str(e), user_id=user_id)
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="Sorry, something went wrong. Please try again."
        )

@slack_app.command("/alfred")
async def handle_alfred_command(ack, body, client):
    """Handle /alfred slash command."""
    await ack()

    try:
        command_text = body.get("text", "").strip()
        user_id = body["user_id"]
        channel_id = body["channel_id"]
        
        # Parse command
        parts = command_text.split(maxsplit=1)
        if not parts:
            await client.chat_postMessage(
                channel=channel_id,
                text="Please specify a command. Try `/alfred help` for available commands."
            )
            return
        
        command = parts[0].lower()
        args = parts[1] if len(parts) > 1 else ""
        
        # Handle different commands
        if command == "help":
            await show_help(client, channel_id)
        elif command == "ping":
            await handle_ping(client, channel_id, user_id)
        elif command == "trend":
            await handle_trend_analysis(client, channel_id, user_id, args)
        elif command == "status":
            await handle_status(client, channel_id, user_id, args)
        elif command == "cancel":
            await handle_cancel(client, channel_id, user_id, args)
        elif command == "chat":
            # Direct conversation with Alfred
            await handle_conversation(client, channel_id, user_id, args)
        else:
            await client.chat_postMessage(
                channel=channel_id,
                text=f"Unknown command: {command}. Try `/alfred help` for available commands."
            )
    
    except Exception as e:
        logger.error("command_handling_failed", error=str(e))
        await client.chat_postMessage(
            channel=channel_id,
            text="Sorry, something went wrong. Please try again."
        )

async def handle_ping(client, channel_id, user_id, thread_ts=None):
    """Handle ping command."""
    try:
        # In a real implementation, this would call the A2A adapter
        # For now, simulate with a direct response
        
        # Store task information in Redis (as an example)
        task_id = f"ping-{int(time.time())}"
        task_data = {
            "intent": "PING",
            "user_id": user_id,
            "channel_id": channel_id,
            "thread_ts": thread_ts,
            "status": "completed",
            "created_at": time.time()
        }
        redis_client.setex(f"task:{task_id}", 3600, json.dumps(task_data))  # Expire after 1 hour
        
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text=f"Pong! 🏓 Task ID: {task_id}"
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
            text="Please provide a trend to analyze. Example: `trend artificial intelligence`"
        )
        return

    try:
        # In a real implementation, this would call the A2A adapter
        # For now, simulate with a direct response
        
        # Store task information in Redis (as an example)
        task_id = f"trend-{int(time.time())}"
        task_data = {
            "intent": "TREND_ANALYSIS",
            "query": query,
            "user_id": user_id,
            "channel_id": channel_id,
            "thread_ts": thread_ts,
            "status": "processing",
            "created_at": time.time()
        }
        redis_client.setex(f"task:{task_id}", 3600, json.dumps(task_data))  # Expire after 1 hour
        
        # Send acknowledgment
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text=f"Analyzing trends for: *{query}*\nTask ID: `{task_id}`"
        )
        
        # Simulate processing time
        await asyncio.sleep(2)
        
        # Update task status
        task_data["status"] = "completed"
        redis_client.setex(f"task:{task_id}", 3600, json.dumps(task_data))
        
        # Send response blocks with rich formatting
        blocks = [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f"Trend Analysis: {query}",
                    "emoji": True
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"Here's a simulated trend analysis for *{query}*. In a real implementation, this would connect to the Social Intelligence service."
                }
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": "*Trend Score:*\n85/100"
                    },
                    {
                        "type": "mrkdwn",
                        "text": "*Growth Rate:*\n+12% MoM"
                    }
                ]
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "*Key Insights:*\n• Growing interest in {query}\n• Related topics include innovation and technology\n• Potential market opportunity identified"
                }
            }
        ]
        
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            blocks=blocks
        )
    except Exception as e:
        logger.error("trend_analysis_failed", error=str(e))
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="Failed to start trend analysis. Please try again."
        )

async def handle_status(client, channel_id, user_id, task_id, thread_ts=None):
    """Handle status command."""
    if not task_id:
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="Please provide a task ID to check. Example: `status 1234abcd`"
        )
        return
    
    try:
        # Get task status from Redis
        task_json = redis_client.get(f"task:{task_id}")
        
        if not task_json:
            await client.chat_postMessage(
                channel=channel_id,
                thread_ts=thread_ts,
                text=f"Task ID `{task_id}` not found or expired."
            )
            return
        
        task = json.loads(task_json)
        status = task.get("status", "unknown")
        intent = task.get("intent", "unknown")
        created_at = task.get("created_at", "unknown")
        
        # Format created_at timestamp
        if isinstance(created_at, (int, float)):
            created_at = datetime.fromtimestamp(created_at).strftime("%Y-%m-%d %H:%M:%S")
        
        # Format a nice status message
        blocks = [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Task Status:* `{task_id}`"
                }
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": f"*Intent:*\n{intent}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Status:*\n{status}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Created:*\n{created_at}"
                    }
                ]
            }
        ]
        
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            blocks=blocks
        )
    except Exception as e:
        logger.error("status_check_failed", error=str(e))
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="Failed to check task status. Please try again."
        )

async def handle_cancel(client, channel_id, user_id, task_id, thread_ts=None):
    """Handle cancel command."""
    if not task_id:
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="Please provide a task ID to cancel. Example: `cancel 1234abcd`"
        )
        return
    
    try:
        # Check if task exists in Redis
        task_json = redis_client.get(f"task:{task_id}")
        
        if not task_json:
            await client.chat_postMessage(
                channel=channel_id,
                thread_ts=thread_ts,
                text=f"Task ID `{task_id}` not found or expired."
            )
            return
        
        # Update task status to cancelled
        task = json.loads(task_json)
        task["status"] = "cancelled"
        redis_client.setex(f"task:{task_id}", 3600, json.dumps(task))
        
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text=f"Task `{task_id}` has been cancelled."
        )
    except Exception as e:
        logger.error("cancel_failed", error=str(e))
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="Failed to cancel task. Please try again."
        )

async def handle_conversation(client, channel_id, user_id, message, thread_ts=None):
    """Handle a conversation message with Alfred."""
    try:
        # First, add a thinking reaction if we have a thread_ts
        if thread_ts:
            try:
                await client.reactions_add(
                    channel=channel_id,
                    timestamp=thread_ts,
                    name="thinking_face"
                )
            except Exception as e:
                # Not critical if this fails
                logger.warning("reaction_add_failed", error=str(e))
        
        # Store conversation in Redis (as an example)
        conv_id = f"conv-{int(time.time())}"
        conv_data = {
            "message": message,
            "user_id": user_id,
            "channel_id": channel_id,
            "thread_ts": thread_ts,
            "timestamp": time.time()
        }
        redis_client.setex(f"conversation:{conv_id}", 3600, json.dumps(conv_data))
        
        # Simulate processing time
        await asyncio.sleep(1)
        
        # Simple response based on content
        if "hello" in message.lower() or "hi" in message.lower():
            response_text = f"Hello there! How can I help you today?"
        elif "help" in message.lower():
            response_text = "I can help with various tasks. Try asking me about trends, or use specific commands like `ping`, `trend <topic>`, or `help`."
        elif "thank" in message.lower():
            response_text = "You're welcome! Let me know if you need anything else."
        else:
            response_text = f"I received your message: '{message}'\n\nI'm still learning to respond to natural language queries. For now, I understand commands like `help`, `ping`, and `trend <topic>`."
        
        # Send the response
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text=response_text
        )
        
        # Remove the thinking reaction if we added one
        if thread_ts:
            try:
                await client.reactions_remove(
                    channel=channel_id,
                    timestamp=thread_ts,
                    name="thinking_face"
                )
            except Exception as e:
                # Not critical if this fails
                logger.warning("reaction_remove_failed", error=str(e))
        
    except Exception as e:
        logger.error("conversation_failed", error=str(e))
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="Sorry, I'm having trouble processing your message. Please try again."
        )

async def show_help(client, channel_id, thread_ts=None):
    """Show enhanced help message with Slack blocks."""
    # Create rich formatting with blocks
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
            "type": "divider"
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*Basic Commands:*\n• `/alfred help` - Show this help message\n• `/alfred ping` - Test bot responsiveness\n• `/alfred chat <message>` - Have a conversation with Alfred"
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*Intelligence:*\n• `/alfred trend <topic>` - Analyze trends for a topic"
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*Task Management:*\n• `/alfred status <task_id>` - Check task status\n• `/alfred cancel <task_id>` - Cancel a running task"
            }
        },
        {
            "type": "divider"
        },
        {
            "type": "context",
            "elements": [
                {
                    "type": "mrkdwn",
                    "text": "💡 *Tip:* You can also send me direct messages without using the `/alfred` prefix!"
                }
            ]
        }
    ]
    
    await client.chat_postMessage(
        channel=channel_id,
        thread_ts=thread_ts,
        blocks=blocks
    )

# Create FastAPI app
app = FastAPI(title="Alfred Bot")

# Add Slack handler
slack_handler = SlackRequestHandler(slack_app)

@app.post("/slack/events")
async def slack_events(request: Request):
    """Handle Slack events."""
    return await slack_handler.handle(request)

@app.get("/slack/health")
async def slack_health():
    """Health check endpoint for ngrok verification."""
    return {"status": "ok", "version": "1.0.0"}

@app.post("/api/chat", response_model=AlfredResponse)
async def chat_endpoint(request: ChatRequest):
    """Chat API endpoint for the Streamlit UI."""
    try:
        # Store conversation in Redis
        conv_id = f"conv-{int(time.time())}"
        conv_data = {
            "message": request.message,
            "user_id": request.user_id,
            "channel_id": request.channel_id,
            "thread_ts": request.thread_ts,
            "interface": "streamlit",
            "timestamp": time.time()
        }
        redis_client.setex(f"conversation:{conv_id}", 3600, json.dumps(conv_data))
        
        # Simple response based on content
        if "hello" in request.message.lower() or "hi" in request.message.lower():
            response_text = f"Hello there! How can I help you today?"
        elif "help" in request.message.lower():
            response_text = "I can help with various tasks. Try asking me about trends, or use specific commands like `ping`, `trend <topic>`, or `help`."
        elif "thank" in request.message.lower():
            response_text = "You're welcome! Let me know if you need anything else."
        else:
            response_text = f"I received your message: '{request.message}'\n\nI'm still learning to respond to natural language queries. For now, I understand commands like `help`, `ping`, and `trend <topic>`."
        
        # For demo purposes, check if we're doing command processing
        first_word = request.message.split()[0].lower() if request.message.split() else ""
        if first_word == "trend" and len(request.message.split()) > 1:
            query = request.message[len("trend"):].strip()
            response_text = f"Trend Analysis for '{query}':\n\n• Trend Score: 85/100\n• Growth Rate: +12% MoM\n• Key Insights: Growing interest in this topic, related to innovation and technology, potential market opportunity identified"
        
        return {"response": response_text, "task_id": conv_id}
    except Exception as e:
        logger.error("chat_api_failed", error=str(e))
        return {"response": "Failed to process chat request", "error": str(e)}
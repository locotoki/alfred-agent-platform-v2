# Alfred Platform Implementation Plan

## Overview

This implementation plan focuses on three key priorities:

1. **Enhanced SlackBot**: Improve the existing alfred-bot integration with more features
2. **HTTP Tunneling**: Configure ngrok for exposing Slack bot endpoints securely
3. **Basic Chat UI**: Implement a Streamlit-based chat interface for testing and administration

## 1. SlackBot Enhancement Plan

The current alfred-bot implementation provides basic slash command functionality but lacks conversational capabilities and better integration with other services.

### Implementation Steps

1. **Enhance Slack Event Handling**
   - Add support for direct messages (DMs)
   - Implement conversation threads
   - Support rich message formatting with blocks

2. **Improve Command Structure**
   - Add conversation state management
   - Implement more sophisticated command parsing
   - Add natural language processing for command interpretation

3. **Extend Service Integration**
   - Connect to Atlas for more advanced capabilities
   - Implement proper integration with social-intel service
   - Add file upload/download capabilities

### Code Implementation

Update the alfred-bot implementation with enhanced features:

```python
# services/alfred-bot/app/enhanced_main.py
from fastapi import FastAPI, Request, BackgroundTasks
from slack_bolt.adapter.fastapi import SlackRequestHandler
from slack_bolt import App
from slack_sdk.web import WebClient
import os
import structlog
import redis
import json
import time
from contextlib import asynccontextmanager

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
    envelope = A2AEnvelope(
        intent="PING",
        content={"message": "ping", "user_id": user_id}
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
            text="Please provide a trend to analyze. Example: `trend artificial intelligence`"
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
        # Get task status from Supabase
        task = await supabase_transport.get_task(task_id)
        
        if not task:
            await client.chat_postMessage(
                channel=channel_id,
                thread_ts=thread_ts,
                text=f"Task ID {task_id} not found."
            )
            return
        
        status = task.get("status", "unknown")
        intent = task.get("intent", "unknown")
        created_at = task.get("created_at", "unknown")
        
        # Format a nice status message
        status_text = f"*Task ID:* {task_id}\n*Intent:* {intent}\n*Status:* {status}\n*Created:* {created_at}"
        
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text=status_text
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
        # Create a cancel task envelope
        envelope = A2AEnvelope(
            intent="CANCEL_TASK",
            content={
                "task_id": task_id,
                "user_id": user_id,
                "channel_id": channel_id
            }
        )
        
        # Publish the cancel request
        message_id = await pubsub_transport.publish_task(envelope)
        
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text=f"Requested cancellation of task {task_id}."
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
    # First, send a typing indicator
    await client.reactions_add(
        channel=channel_id,
        timestamp=thread_ts or time.time(),
        name="thinking_face"
    )
    
    try:
        # Create a conversation task envelope
        envelope = A2AEnvelope(
            intent="CONVERSATION",
            content={
                "message": message,
                "user_id": user_id,
                "channel_id": channel_id,
                "thread_ts": thread_ts,
                "interface": "slack"
            }
        )
        
        # Store and publish the task
        task_id = await supabase_transport.store_task(envelope)
        message_id = await pubsub_transport.publish_task(envelope)
        
        # Send an initial acknowledgment
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="I'm processing your message, please wait a moment..."
        )
        
        # In a real implementation, we would wait for a response from the agent
        # For now, simulate with a generic response
        await asyncio.sleep(2)  # Simulate processing time
        
        # Send a more helpful response
        blocks = [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"I've received your message: *{message}*\n\nI'm still learning to respond to natural language queries. Try using specific commands like `help`, `ping`, or `trend <topic>` for more structured interactions."
                }
            }
        ]
        
        await client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            blocks=blocks
        )
        
        # Remove the thinking reaction
        await client.reactions_remove(
            channel=channel_id,
            timestamp=thread_ts or time.time(),
            name="thinking_face"
        )
        
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

@app.get("/slack/health")
async def slack_health():
    """Health check endpoint for ngrok verification."""
    return {"status": "ok", "version": "1.0.0"}
```

### Updated requirements.txt

```
fastapi==0.104.1
uvicorn==0.24.0
pydantic==2.5.2
structlog==23.2.0
redis==5.0.1
slack-bolt==1.18.0
slack-sdk==3.23.0
httpx==0.25.0
asyncio==3.4.3
python-dotenv==1.0.0
```

## 2. HTTP Tunneling with ngrok

Ngrok allows for exposing the local Slack bot to the public internet securely, making it accessible to Slack's API.

### Installation & Setup

1. **Install ngrok**
   ```bash
   # Download and install ngrok
   curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list && sudo apt update && sudo apt install ngrok
   ```

2. **Configure ngrok**
   ```bash
   # Authenticate with your ngrok token
   ngrok config add-authtoken YOUR_NGROK_AUTH_TOKEN
   ```

3. **Create ngrok configuration file**
   ```yaml
   # ~/ngrok-alfred.yml
   version: 2
   authtoken: YOUR_NGROK_AUTH_TOKEN
   tunnels:
     alfred-bot:
       proto: http
       addr: 8011
       subdomain: alfred-platform # If you have a paid plan
   ```

4. **Start ngrok tunnel**
   ```bash
   ngrok start --config=~/ngrok-alfred.yml alfred-bot
   ```

5. **Verify the tunnel**
   - Access the public URL (e.g., https://alfred-platform.ngrok.io/slack/health)
   - The health endpoint should return `{"status": "ok", "version": "1.0.0"}`

### Integration with Slack

1. **Update Slack App Configuration**
   - Go to https://api.slack.com/apps
   - Select your application
   - Under "Event Subscriptions"
     - Set Request URL to: `https://your-ngrok-domain.ngrok.io/slack/events`
     - Subscribe to bot events: `message.im`, `app_mention`
   - Under "Slash Commands"
     - Update the `/alfred` command URL to: `https://your-ngrok-domain.ngrok.io/slack/events`
   - Save changes

2. **Create an ngrok service**
   ```bash
   # Create systemd service for persistent ngrok
   sudo tee /etc/systemd/system/ngrok-alfred.service > /dev/null << 'EOF'
   [Unit]
   Description=ngrok tunnel for Alfred Slack Bot
   After=network.target

   [Service]
   ExecStart=ngrok start --config=/home/locotoki/ngrok-alfred.yml alfred-bot
   Restart=always
   User=locotoki
   Group=locotoki

   [Install]
   WantedBy=multi-user.target
   EOF

   # Enable and start the service
   sudo systemctl enable ngrok-alfred
   sudo systemctl start ngrok-alfred
   ```

## 3. Basic Chat UI with Streamlit

Streamlit provides a quick way to create a web-based chat interface for testing and administration.

### Implementation

1. **Create Streamlit Chat App**

```python
# chat_ui.py
import streamlit as st
import requests
import json
import time
import os
from datetime import datetime

# Configure the page
st.set_page_config(
    page_title="Alfred Chat Interface",
    page_icon="🤖",
    layout="wide"
)

# Application constants
API_URL = os.environ.get("ALFRED_API_URL", "http://localhost:8011")

# Initialize session state for chat history
if "messages" not in st.session_state:
    st.session_state.messages = []

# Function to send messages to Alfred
def send_message(message):
    try:
        # Call the Alfred API endpoint
        response = requests.post(
            f"{API_URL}/api/chat",
            json={"message": message, "user_id": "streamlit_user", "channel_id": "streamlit_channel"},
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            return response.json().get("response", "No response received")
        else:
            return f"Error: {response.status_code} - {response.text}"
    except Exception as e:
        return f"Error communicating with Alfred: {str(e)}"

# Sidebar controls
with st.sidebar:
    st.title("Alfred Chat Interface")
    st.divider()
    
    st.subheader("Configuration")
    api_url = st.text_input("API URL", value=API_URL)
    
    if st.button("Clear Chat History"):
        st.session_state.messages = []
        st.experimental_rerun()
    
    st.divider()
    st.subheader("About")
    st.write("This is a simple chat interface for testing Alfred's capabilities.")
    st.write("Version: 1.0.0")

# Main chat interface
st.title("Alfred Chat Interface")

# Display chat messages
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.write(message["content"])

# Chat input
prompt = st.chat_input("Send a message to Alfred...")

if prompt:
    # Display user message
    with st.chat_message("user"):
        st.write(prompt)
    
    # Add user message to history
    st.session_state.messages.append({"role": "user", "content": prompt, "time": datetime.now().isoformat()})
    
    # Display thinking indicator
    with st.chat_message("assistant"):
        message_placeholder = st.empty()
        message_placeholder.write("Thinking...")
        
        # Send message to Alfred and get response
        response = send_message(prompt)
        
        # Update with actual response
        message_placeholder.write(response)
    
    # Add assistant response to history
    st.session_state.messages.append({"role": "assistant", "content": response, "time": datetime.now().isoformat()})
```

2. **Create new API endpoint in Alfred Bot**

Add a new endpoint to the FastAPI app to support the chat UI:

```python
# Add to services/alfred-bot/app/main.py

from pydantic import BaseModel

class ChatRequest(BaseModel):
    message: str
    user_id: str
    channel_id: str

@app.post("/api/chat")
async def chat_endpoint(request: ChatRequest):
    """Chat API endpoint for the Streamlit UI."""
    try:
        # Create a conversation task envelope
        envelope = A2AEnvelope(
            intent="CONVERSATION",
            content={
                "message": request.message,
                "user_id": request.user_id,
                "channel_id": request.channel_id,
                "interface": "streamlit"
            }
        )
        
        # Store and publish the task
        task_id = await supabase_transport.store_task(envelope)
        message_id = await pubsub_transport.publish_task(envelope)
        
        # For now, use a mock response
        # In a real implementation, we would wait for the response from the agent
        response = f"I've received your message: '{request.message}'. I'm still learning to respond to natural language queries."
        
        return {"response": response, "task_id": envelope.task_id}
    except Exception as e:
        logger.error("chat_api_failed", error=str(e))
        return {"error": "Failed to process chat request", "details": str(e)}
```

3. **Install Streamlit Dependencies**

```bash
pip install streamlit
```

4. **Run the Streamlit App**

```bash
streamlit run chat_ui.py
```

## 4. Integration Plan

1. **Setup and Configuration (Day 1)**
   - Set up ngrok and configure tunneling
   - Update Slack app configuration
   - Install necessary dependencies

2. **SlackBot Enhancement (Days 2-3)**
   - Implement enhanced SlackBot features
   - Add conversation capabilities
   - Test with Slack workspace

3. **Chat UI Development (Day 4)**
   - Implement Streamlit chat interface
   - Connect to Alfred API
   - Test functionality

4. **Testing and Refinement (Day 5)**
   - End-to-end testing of all components
   - Refine UI and interaction flows
   - Document usage and configuration

## 5. Future Enhancements

1. **Advanced Conversation Management**
   - Implement conversation state tracking
   - Add context-aware responses
   - Implement multi-turn dialogue

2. **Integration with Atlas Worker**
   - Connect to Atlas for more advanced reasoning
   - Add knowledge retrieval capabilities
   - Implement structured data handling

3. **UI Improvements**
   - Add rich visualizations for trend analysis
   - Implement user authentication
   - Create admin dashboard for monitoring

4. **Deployment and Scaling**
   - Package as Docker containers
   - Set up automatic scaling
   - Implement high availability configurations
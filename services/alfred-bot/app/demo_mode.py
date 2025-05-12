from fastapi import FastAPI, Request
import os
import structlog
import redis
from contextlib import asynccontextmanager
import re
from datetime import datetime
import uuid
import json

from libs.a2a_adapter import A2AEnvelope, PubSubTransport, SupabaseTransport, PolicyMiddleware
from libs.agent_core.health import create_health_app

logger = structlog.get_logger(__name__)

# Initialize services with stub implementations
pubsub_transport = PubSubTransport(
    project_id=os.getenv("GCP_PROJECT_ID", "alfred-agent-platform")
)

supabase_transport = SupabaseTransport(
    database_url=os.getenv("DATABASE_URL")
)

redis_client = redis.from_url(os.getenv("REDIS_URL", "redis://redis:6379"))
policy_middleware = PolicyMiddleware(redis_client)

# Create FastAPI app
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle."""
    # Startup
    await supabase_transport.connect()
    logger.info("alfred_bot_demo_started")

    yield

    # Shutdown
    await supabase_transport.disconnect()
    logger.info("alfred_bot_demo_stopped")

app = FastAPI(title="Alfred Bot (Demo Mode)", lifespan=lifespan)

# Add health check endpoints
health_app = create_health_app("alfred-bot-demo", "1.0.0")
app.mount("/health", health_app)

@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "status": "ok",
        "message": "Alfred Bot API running in demo mode",
        "version": "1.0.0",
        "mode": "demo"
    }

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
        # Process the chat message with demo responses
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
            # Generate a random task ID for demo purposes
            task_id = f"demo-{str(uuid.uuid4())[:8]}"
            return {
                "status": "success",
                "response": f"Pong! Alfred is responsive. Task ID: {task_id}"
            }
        elif command == "trend" and args:
            # Generate a random task ID for demo purposes
            task_id = f"trend-{str(uuid.uuid4())[:8]}"
            
            return {
                "status": "success",
                "response": f"Analyzing trends for: {args}\nTask ID: {task_id}\n\n*This is a demo response*\n\nTrend Analysis: {args}\n\nTrend Score: 85/100\nGrowth Rate: +12% MoM\n\nKey Insights:\n• Growing interest in this topic\n• Related topics include AI and data analytics\n• Potential market opportunity identified"
            }
        elif command == "status":
            return {
                "status": "success",
                "response": f"Task status: Complete\n\nThis is a demo response. In production, this would show the actual status of task '{args}'."
            }
        else:
            # General chat message - respond with demo message
            return {
                "status": "success",
                "response": f"I received your message: \"{message}\"\n\nThis is a demo response. In production, this would be processed by the appropriate agent and a more relevant response would be provided."
            }
    
    except Exception as e:
        logger.error("chat_api_failed", error=str(e))
        return {"status": "error", "message": f"Error processing message: {str(e)}"}


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

    # In demo mode, just log the response
    logger.info("demo_task_response_received", 
                task_id=task_id, 
                channel_id=channel_id, 
                response_preview=str(response)[:100])

    return {"status": "success", "demo": True}


def get_help_response_markdown():
    """Get help response in markdown format."""
    return """
## Alfred Bot Commands (Demo Mode)

I can help you with various tasks through commands:

### Basic Commands:
- `help` - Show this help message
- `ping` - Test bot responsiveness

### Intelligence:
- `trend <topic>` - Analyze trends for a topic (demo responses)

### Task Management:
- `status <task_id>` - Check task status (demo responses)
- `cancel <task_id>` - Cancel a running task (demo responses)

**Note:** This is running in demo mode, so all responses are simulated and not connected to actual processing services.
"""
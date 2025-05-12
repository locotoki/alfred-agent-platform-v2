from fastapi import FastAPI, Request
from datetime import datetime
import uuid
import uvicorn

app = FastAPI(title="Alfred Bot Demo API")

@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "status": "ok",
        "message": "Alfred Bot Demo API running",
        "version": "1.0.0"
    }

@app.get("/health")
async def health():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "service": "alfred-bot-demo"
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
        print(f"Error processing message: {str(e)}")
        return {"status": "error", "message": f"Error processing message: {str(e)}"}


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

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8011)
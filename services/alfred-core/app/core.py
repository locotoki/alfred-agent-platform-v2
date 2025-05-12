"""
Core API implementation for Alfred.
This module provides the shared business logic and API endpoints used by all interfaces.
"""

import os
import uuid
from datetime import datetime
from typing import Dict, Any, Optional, List

import structlog
from fastapi import FastAPI, Request, HTTPException, Depends
from pydantic import BaseModel, Field

from app.model_client import ModelClient

logger = structlog.get_logger(__name__)

# Models for API requests and responses
class ChatRequest(BaseModel):
    """Request model for chat messages."""
    message: str
    user_id: str
    channel_id: str
    thread_ts: Optional[str] = None
    model: Optional[str] = None  # Optional model to use for the response

class ChatResponse(BaseModel):
    """Response model for chat messages."""
    status: str
    response: str

class TaskModel(BaseModel):
    """Model for task information."""
    task_id: str
    status: str
    type: str
    created_at: datetime
    updated_at: datetime
    user_id: str
    channel_id: str
    thread_ts: Optional[str] = None
    content: Dict[str, Any] = Field(default_factory=dict)

class TaskResponse(BaseModel):
    """Response model for task-related endpoints."""
    status: str
    task: Optional[TaskModel] = None
    message: Optional[str] = None

class HealthResponse(BaseModel):
    """Response model for health check endpoint."""
    status: str
    timestamp: datetime
    service: str
    version: str
    interfaces: List[str]

# Core business logic
class AlfredCore:
    """
    Core business logic for Alfred, independent of interface.
    This class implements the shared functionality that all interfaces use.
    """

    def __init__(self, mode: str = "default"):
        """
        Initialize the Alfred core with the specified mode.

        Args:
            mode: The operating mode ("default", "demo", "slack", etc.)
        """
        self.mode = mode
        self.version = "1.0.0"
        self.model_client = ModelClient()  # Initialize the model client
        logger.info("alfred_core_initialized", mode=mode, version=self.version)
    
    async def process_message(self, message: str, user_id: str, channel_id: str, thread_ts: Optional[str] = None, model: Optional[str] = None) -> str:
        """
        Process a message from any interface and generate a response.

        Args:
            message: The user's message text
            user_id: Identifier for the user
            channel_id: Identifier for the conversation channel
            thread_ts: Thread identifier for threaded conversations
            model: Optional model ID to use for the response

        Returns:
            Response text to be sent back to the user
        """
        # Parse command structure
        parts = message.split(maxsplit=1)
        command = parts[0].lower() if parts else ""
        args = parts[1] if len(parts) > 1 else ""

        # Log request with model information
        logger.info(
            "processing_message",
            user_id=user_id,
            channel_id=channel_id,
            thread_ts=thread_ts,
            model=model,
            command=command
        )

        # Process based on command
        if command == "help":
            return self.get_help_response()
        elif command == "ping":
            return self.handle_ping()
        elif command == "trend" and args:
            return await self.handle_trend_analysis(args, user_id, channel_id, thread_ts, model)
        elif command == "status" and args:
            return await self.get_task_status(args)
        elif command == "models":
            return await self.list_available_models()
        else:
            # Generic chat response
            if self.mode == "demo":
                return f"I received your message: \"{message}\"\n\nThis is a demo response. In production, this would be processed by the appropriate agent and a more relevant response would be provided."
            else:
                try:
                    # Use the model client to process the message
                    response = self.model_client.process_with_model(
                        content=message,
                        model=model,
                        task_type="chat",
                        parameters={
                            "user_id": user_id,
                            "channel_id": channel_id,
                            "thread_ts": thread_ts
                        }
                    )

                    # Extract response text
                    if "response" in response:
                        return response["response"]
                    else:
                        # Add the routing info to help debugging
                        model_info = ""
                        if "_routing" in response:
                            routing = response["_routing"]
                            model_info = f"\n\nProcessed with model: {routing['model']}"

                        return f"{response.get('content', 'No response content')}{model_info}"
                except Exception as e:
                    # Fallback to simple response on error
                    logger.error("model_processing_failed", error=str(e))
                    task_id = f"chat-{str(uuid.uuid4())[:8]}"
                    return f"I'll process your message and get back to you shortly. Task ID: {task_id}"
    
    def get_help_response(self) -> str:
        """
        Generate the help response with available commands.

        Returns:
            Formatted help text
        """
        return """
## Alfred Bot Commands

I can help you with various tasks through commands:

### Basic Commands:
- `help` - Show this help message
- `ping` - Test bot responsiveness
- `models` - List available LLM models

### Intelligence:
- `trend <topic>` - Analyze trends for a topic

### Task Management:
- `status <task_id>` - Check task status
- `cancel <task_id>` - Cancel a running task
"""
    
    def handle_ping(self) -> str:
        """
        Handle the ping command.
        
        Returns:
            Ping response with task ID
        """
        task_id = f"ping-{str(uuid.uuid4())[:8]}"
        return f"Pong! Alfred is responsive. Task ID: {task_id}"
    
    async def list_available_models(self) -> str:
        """
        List all available LLM models.

        Returns:
            Formatted list of models
        """
        try:
            models = self.model_client.get_available_models()

            # Format the models for display
            models_by_provider = {}
            for model in models:
                provider = model.get("provider", "unknown")
                if provider not in models_by_provider:
                    models_by_provider[provider] = []
                models_by_provider[provider].append(model)

            # Build the response text
            response = "## Available Models\n\n"

            for provider, provider_models in models_by_provider.items():
                response += f"### {provider.title()}\n"
                for model in provider_models:
                    display_name = model.get("display_name", model.get("name", "Unknown"))
                    description = model.get("description", "")
                    model_id = model.get("name", "unknown")
                    response += f"- **{display_name}** ({model_id})"
                    if description:
                        response += f": {description}"
                    response += "\n"
                response += "\n"

            return response

        except Exception as e:
            logger.error("list_models_failed", error=str(e))
            return f"Error fetching models: {str(e)}"

    async def handle_trend_analysis(
        self,
        query: str,
        user_id: str,
        channel_id: str,
        thread_ts: Optional[str] = None,
        model: Optional[str] = None
    ) -> str:
        """
        Handle a trend analysis request.

        Args:
            query: The trend topic to analyze
            user_id: Identifier for the user
            channel_id: Identifier for the conversation channel
            thread_ts: Thread identifier for threaded conversations
            model: Optional model ID to use for the analysis

        Returns:
            Response with task information
        """
        task_id = f"trend-{str(uuid.uuid4())[:8]}"

        if self.mode == "demo":
            # In demo mode, return a mock analysis immediately
            return f"Analyzing trends for: {query}\nTask ID: {task_id}\n\n*This is a demo response*\n\nTrend Analysis: {query}\n\nTrend Score: 85/100\nGrowth Rate: +12% MoM\n\nKey Insights:\n• Growing interest in this topic\n• Related topics include AI and data analytics\n• Potential market opportunity identified"
        else:
            try:
                # Use the model client to process the trend analysis
                prompt = f"Perform a trend analysis for the topic: {query}. Include key metrics, growth indicators, and insights."

                response = self.model_client.process_with_model(
                    content=prompt,
                    model=model,
                    task_type="analysis",
                    parameters={
                        "user_id": user_id,
                        "channel_id": channel_id,
                        "thread_ts": thread_ts,
                        "task_id": task_id
                    }
                )

                # Extract response text
                if "response" in response:
                    analysis = response["response"]
                    return f"Trend Analysis for: {query}\nTask ID: {task_id}\n\n{analysis}"
                else:
                    model_info = ""
                    if "_routing" in response:
                        routing = response["_routing"]
                        model_info = f" (using {routing['model']})"

                    return f"Analyzing trends for: {query}\nTask ID: {task_id}{model_info}\n\nAnalysis in progress..."

            except Exception as e:
                # Fallback to simple response on error
                logger.error("trend_analysis_failed", error=str(e), task_id=task_id)
                logger.info("trend_analysis_task_created", task_id=task_id, query=query, user_id=user_id)
                return f"Analyzing trends for: {query}\nTask ID: {task_id}"
    
    async def get_task_status(self, task_id: str) -> str:
        """
        Get the status of a task.
        
        Args:
            task_id: The ID of the task to check
            
        Returns:
            Task status information
        """
        # In a real implementation, this would look up the task in a database
        if self.mode == "demo":
            return f"Task status: Complete\n\nThis is a demo response. In production, this would show the actual status of task '{task_id}'."
        else:
            return f"Task ID: {task_id}\nStatus: In Progress\nCreated: {datetime.now().isoformat()}"

# Create FastAPI application with Alfred core
def create_app(mode: str = "default", lifespan=None) -> FastAPI:
    """
    Create a FastAPI application with Alfred core functionality.

    Args:
        mode: The operating mode for the core ("default", "demo", "slack", etc.)
        lifespan: Optional lifespan context manager for the application

    Returns:
        Configured FastAPI application
    """
    app = FastAPI(title="Alfred API", version="1.0.0", lifespan=lifespan)
    core = AlfredCore(mode=mode)
    
    @app.get("/")
    async def root():
        """Root endpoint showing API information."""
        return {
            "service": "Alfred API",
            "version": core.version,
            "mode": core.mode,
            "status": "operational"
        }
    
    @app.get("/health")
    async def health():
        """Health check endpoint."""
        interfaces = ["api"]
        if os.getenv("SLACK_BOT_TOKEN"):
            interfaces.append("slack")
        
        return HealthResponse(
            status="healthy",
            timestamp=datetime.now(),
            service="alfred-core",
            version=core.version,
            interfaces=interfaces
        )
    
    @app.post("/api/chat", response_model=ChatResponse)
    async def chat(request: ChatRequest):
        """Handle chat requests from any interface."""
        try:
            response = await core.process_message(
                request.message,
                request.user_id,
                request.channel_id,
                request.thread_ts,
                request.model
            )
            return ChatResponse(status="success", response=response)
        except Exception as e:
            logger.error("chat_processing_failed", error=str(e))
            raise HTTPException(status_code=500, detail=f"Error processing message: {str(e)}")
    
    @app.get("/api/task/{task_id}", response_model=TaskResponse)
    async def get_task(task_id: str):
        """Get information about a task."""
        try:
            response = await core.get_task_status(task_id)
            return TaskResponse(status="success", message=response)
        except Exception as e:
            logger.error("task_retrieval_failed", error=str(e), task_id=task_id)
            raise HTTPException(status_code=500, detail=f"Error retrieving task: {str(e)}")
    
    # Add more endpoints as needed
    
    return app
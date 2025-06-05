"""Alfred Core Service - Main application entry point."""

import time

import structlog
from fastapi import FastAPI
from fastapi.responses import PlainTextResponse
from prometheus_client import Counter, Histogram, generate_latest

# Configure structured logging
logger = structlog.get_logger()


# WhatsApp chat handler (placeholder implementation)
async def chat_handler(text: str, from_user: str) -> str:
    """Handle incoming WhatsApp messages and return responses."""
    logger.info("Processing WhatsApp message", text=text, from_user=from_user)

    # Simple echo response for now - replace with actual AI/agent logic
    if "hello" in text.lower():
        return f"Hello {from_user}! How can I help you today?"
    elif "help" in text.lower():
        return "I'm Alfred, your AI assistant. I can help with various tasks!"
    else:
        return (
            f"I received your message: '{text}'. This is a placeholder response from Alfred Core."
        )


# Create FastAPI app
app = FastAPI(title="Alfred Core Service", version="0.9.6")


@app.on_event("startup")
async def startup():
    """Initialize services on startup."""
    logger.info("Starting Alfred Core service")

    # Initialize WhatsApp bridge
    try:
        from .wa_bridge import start as wa_start

        wa_start(chat_handler)
        logger.info("WhatsApp bridge initialized")
    except Exception as e:
        logger.warning("WhatsApp bridge initialization failed", error=str(e))


# Prometheus metrics
request_count = Counter(
    "alfred_core_requests_total", "Total requests", ["method", "endpoint", "status"]
)
request_duration = Histogram(
    "alfred_core_request_duration_seconds", "Request duration", ["method", "endpoint"]
)


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "service": "alfred-core",
        "version": "0.9.6",
        "timestamp": int(time.time()),
    }


@app.get("/metrics", response_class=PlainTextResponse)
async def metrics():
    """Prometheus metrics endpoint."""
    return generate_latest()


@app.get("/")
async def root():
    """Root endpoint."""
    request_count.labels(method="GET", endpoint="/", status="200").inc()
    return {
        "service": "alfred-core",
        "status": "operational",
        "endpoints": {"health": "/health", "metrics": "/metrics", "api": "/api/v1"},
    }


@app.get("/api/v1/status")
async def api_status():
    """Return API status."""
    with request_duration.labels(method="GET", endpoint="/api/v1/status").time():
        request_count.labels(method="GET", endpoint="/api/v1/status", status="200").inc()
        logger.info("Status check requested")
        return {
            "api_version": "v1",
            "status": "active",
            "capabilities": ["agent-orchestration", "task-routing", "metric-collection"],
        }


@app.post("/api/v1/tasks")
async def create_task(task: dict):
    """Create a new task (placeholder)."""
    request_count.labels(method="POST", endpoint="/api/v1/tasks", status="201").inc()
    logger.info("Task created", task_id=task.get("id", "unknown"))
    return {"task_id": "task-123", "status": "queued", "message": "Task queued for processing"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8011)

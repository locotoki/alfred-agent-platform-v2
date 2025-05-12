"""
Main module for the CrewAI service.
Provides a FastAPI application for managing CrewAI crews and tasks.
"""

import os
import asyncio
import json
import logging
from typing import Dict, Any, Optional, List

import uvicorn
from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks, Request
from fastapi.middleware.cors import CORSMiddleware
from google.cloud import pubsub_v1
import structlog
from prometheus_client import Counter, Histogram, start_http_server

from crewai_service.crews.base_crew import BaseCrew
from crewai_service.crews.registry import CREW_REGISTRY

# Configure logging
logger = structlog.get_logger(__name__)

# Configure environment variables
PORT = int(os.getenv("CREWAI_PORT", "9004"))
METRICS_PORT = int(os.getenv("CREWAI_METRICS_PORT", "9005"))
PROJECT_ID = os.getenv("ALFRED_PROJECT_ID", "alfred-agent-platform")
PUBSUB_EMULATOR_HOST = os.getenv("ALFRED_PUBSUB_EMULATOR_HOST")
LOG_LEVEL = os.getenv("CREWAI_LOG_LEVEL", "INFO")

# Configure Prometheus metrics
CREW_TASK_COUNTER = Counter(
    "crewai_tasks_total", 
    "Total number of CrewAI tasks processed",
    ["crew_type", "status"]
)

CREW_TASK_DURATION = Histogram(
    "crewai_task_duration_seconds",
    "Time taken to process CrewAI tasks",
    ["crew_type"]
)

API_REQUESTS = Counter(
    "crewai_api_requests_total",
    "Total API requests",
    ["endpoint", "method", "status"]
)

ACTIVE_TASKS = Counter(
    "crewai_active_tasks",
    "Currently processing CrewAI tasks",
    ["crew_type"]
)

# Initialize FastAPI app
app = FastAPI(
    title="CrewAI Service",
    description="Multi-agent orchestration service for Alfred Agent Platform",
    version="0.1.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize PubSub subscriber
subscriber = pubsub_v1.SubscriberClient()
subscription_path = subscriber.subscription_path(
    PROJECT_ID, "crew-tasks-subscription"
)

# In-memory task store
active_tasks: Dict[str, Dict[str, Any]] = {}


async def process_crew_task(crew_type: str, task_data: Dict[str, Any]) -> Dict[str, Any]:
    """Process a CrewAI task asynchronously."""
    task_id = task_data.get("task_id", "unknown")
    tenant_id = task_data.get("tenant_id")
    
    # Create the appropriate crew based on type
    if crew_type not in CREW_REGISTRY:
        raise ValueError(f"Unknown crew type: {crew_type}")
    
    # Initialize the crew
    crew_class = CREW_REGISTRY[crew_type]
    crew = crew_class(crew_id=task_id, tenant_id=tenant_id, project_id=PROJECT_ID)
    
    # Track metrics
    ACTIVE_TASKS.labels(crew_type=crew_type).inc()
    CREW_TASK_COUNTER.labels(crew_type=crew_type, status="started").inc()
    
    try:
        # Execute the crew with the provided task data
        with CREW_TASK_DURATION.labels(crew_type=crew_type).time():
            result = await crew.run(context=task_data.get("content", {}))
        
        # Update metrics
        CREW_TASK_COUNTER.labels(crew_type=crew_type, status="completed").inc()
        
        return result
    except Exception as e:
        # Log error and update metrics
        logger.error(
            "crew_task_failed",
            error=str(e),
            crew_type=crew_type,
            task_id=task_id
        )
        CREW_TASK_COUNTER.labels(crew_type=crew_type, status="failed").inc()
        raise
    finally:
        # Decrease active tasks counter
        ACTIVE_TASKS.labels(crew_type=crew_type).dec()


async def handle_pubsub_message(message):
    """Handle incoming PubSub messages."""
    try:
        # Decode message data
        data = json.loads(message.data.decode("utf-8"))
        
        # Extract crew type and task data
        crew_type = data.get("crew_type")
        if not crew_type:
            logger.error("missing_crew_type", data=data)
            message.ack()
            return
        
        # Process the task
        await process_crew_task(crew_type, data)
        
        # Acknowledge the message
        message.ack()
        
    except Exception as e:
        logger.error("pubsub_message_processing_error", error=str(e))
        # Negative acknowledgment to retry
        message.nack()


async def start_pubsub_subscriber():
    """Start the PubSub subscriber in the background."""
    # Define the callback function
    def callback(message):
        asyncio.create_task(handle_pubsub_message(message))
    
    # Start the subscriber
    streaming_pull_future = subscriber.subscribe(
        subscription_path, callback=callback
    )
    
    logger.info(
        "pubsub_subscriber_started",
        subscription=subscription_path
    )
    
    # Keep the subscriber running
    try:
        await asyncio.get_running_loop().run_in_executor(
            None, streaming_pull_future.result
        )
    except Exception as e:
        streaming_pull_future.cancel()
        logger.error("pubsub_subscriber_error", error=str(e))


@app.on_event("startup")
async def startup_event():
    """Initialize services on startup."""
    # Start Prometheus metrics server
    start_http_server(METRICS_PORT)
    logger.info("metrics_server_started", port=METRICS_PORT)
    
    # Start PubSub subscriber
    asyncio.create_task(start_pubsub_subscriber())
    
    logger.info("crewai_service_started", port=PORT)


@app.on_event("shutdown")
async def shutdown_event():
    """Clean up resources on shutdown."""
    # Close PubSub subscriber
    subscriber.close()
    
    logger.info("crewai_service_stopped")


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "version": "0.1.0"}


@app.get("/crews")
async def list_crews():
    """List available crew types."""
    return {"crews": list(CREW_REGISTRY.keys())}


@app.post("/crews/{crew_type}/tasks")
async def create_crew_task(
    crew_type: str,
    task_data: Dict[str, Any],
    background_tasks: BackgroundTasks,
    request: Request
):
    """Create a new CrewAI task."""
    API_REQUESTS.labels(
        endpoint=f"/crews/{crew_type}/tasks",
        method="POST",
        status="processing"
    ).inc()
    
    try:
        # Validate crew type
        if crew_type not in CREW_REGISTRY:
            API_REQUESTS.labels(
                endpoint=f"/crews/{crew_type}/tasks",
                method="POST",
                status="error"
            ).inc()
            raise HTTPException(
                status_code=404,
                detail=f"Crew type '{crew_type}' not found"
            )
        
        # Generate task ID if not provided
        if "task_id" not in task_data:
            import uuid
            task_data["task_id"] = str(uuid.uuid4())
        
        # Add to task store
        task_id = task_data["task_id"]
        active_tasks[task_id] = {
            "status": "pending",
            "crew_type": crew_type,
            "task_data": task_data,
            "created_at": asyncio.get_event_loop().time()
        }
        
        # Process task in background
        background_tasks.add_task(
            process_crew_task, crew_type, task_data
        )
        
        API_REQUESTS.labels(
            endpoint=f"/crews/{crew_type}/tasks",
            method="POST",
            status="success"
        ).inc()
        
        return {
            "status": "accepted",
            "task_id": task_id,
            "message": f"{crew_type} task has been queued"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        API_REQUESTS.labels(
            endpoint=f"/crews/{crew_type}/tasks",
            method="POST",
            status="error"
        ).inc()
        logger.error("create_task_error", error=str(e), crew_type=crew_type)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create task: {str(e)}"
        )


@app.get("/tasks/{task_id}")
async def get_task_status(task_id: str):
    """Get the status of a specific task."""
    API_REQUESTS.labels(
        endpoint="/tasks/{task_id}",
        method="GET",
        status="processing"
    ).inc()
    
    try:
        # Check if task exists
        if task_id not in active_tasks:
            API_REQUESTS.labels(
                endpoint="/tasks/{task_id}",
                method="GET",
                status="error"
            ).inc()
            raise HTTPException(
                status_code=404,
                detail=f"Task {task_id} not found"
            )
        
        API_REQUESTS.labels(
            endpoint="/tasks/{task_id}",
            method="GET",
            status="success"
        ).inc()
        
        return active_tasks[task_id]
        
    except HTTPException:
        raise
    except Exception as e:
        API_REQUESTS.labels(
            endpoint="/tasks/{task_id}",
            method="GET",
            status="error"
        ).inc()
        logger.error("get_task_status_error", error=str(e), task_id=task_id)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get task status: {str(e)}"
        )


@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint."""
    return {"message": "Metrics available at port " + str(METRICS_PORT)}


@app.get("/metrics/summary")
async def metrics_summary():
    """Summary of metrics for dashboard reporting."""
    # Calculate metrics from counters and histograms
    from prometheus_client import REGISTRY

    # Extract metrics from Prometheus registry
    metrics = {}
    for metric in REGISTRY.collect():
        for sample in metric.samples:
            # Handle crew tasks metrics
            if sample.name == 'crewai_tasks_total_total':
                crew_type = sample.labels.get('crew_type', 'unknown')
                status = sample.labels.get('status', 'unknown')

                if 'totalTasks' not in metrics:
                    metrics['totalTasks'] = 0

                metrics['totalTasks'] += sample.value

                # Track tasks by status
                status_key = f"{status}_tasks"
                if status_key not in metrics:
                    metrics[status_key] = 0
                metrics[status_key] += sample.value

                # Track tasks by crew type
                crew_key = f"crew_{crew_type}_tasks"
                if crew_key not in metrics:
                    metrics[crew_key] = 0
                metrics[crew_key] += sample.value

            # Handle task duration metrics
            elif sample.name.startswith('crewai_task_duration_seconds_'):
                crew_type = sample.labels.get('crew_type', 'unknown')

                if 'averageExecutionTime' not in metrics:
                    metrics['averageExecutionTime'] = 0
                    metrics['taskCount'] = 0

                # This is a simplification - in a real implementation you'd use proper histogram calculations
                if sample.name.endswith('_sum'):
                    metrics['averageExecutionTime'] += sample.value
                elif sample.name.endswith('_count'):
                    metrics['taskCount'] += sample.value

    # Calculate success rate and average execution time
    completed_tasks = metrics.get('completed_tasks', 0)
    failed_tasks = metrics.get('failed_tasks', 0)
    total_task_count = metrics.get('totalTasks', 0)

    if total_task_count > 0:
        metrics['successRate'] = completed_tasks / total_task_count
    else:
        metrics['successRate'] = 0

    if metrics.get('taskCount', 0) > 0:
        metrics['averageExecutionTime'] = metrics['averageExecutionTime'] / metrics['taskCount']
    else:
        metrics['averageExecutionTime'] = 0

    # Get top crews by usage
    crew_metrics = []
    for key, value in metrics.items():
        if key.startswith('crew_') and key.endswith('_tasks'):
            crew_name = key[5:-6]  # Extract crew name from 'crew_NAME_tasks'
            crew_metrics.append({"name": crew_name, "count": int(value)})

    # Sort crews by count and take top 5
    top_crews = sorted(crew_metrics, key=lambda x: x['count'], reverse=True)[:5]
    metrics['topCrews'] = top_crews

    # Remove intermediate calculation fields
    if 'taskCount' in metrics:
        del metrics['taskCount']

    # Previous metrics for comparison (in a real implementation, these would be from storage)
    # For now we'll just set these to 90% of current values as placeholders
    metrics['previousTotalTasks'] = int(metrics.get('totalTasks', 0) * 0.9)
    metrics['previousSuccessRate'] = metrics.get('successRate', 0) * 0.9

    return metrics


if __name__ == "__main__":
    # Run the FastAPI app
    uvicorn.run(
        "crewai_service.main:app",
        host="0.0.0.0",
        port=PORT,
        reload=os.getenv("CREWAI_ENV", "production") == "development"
    )
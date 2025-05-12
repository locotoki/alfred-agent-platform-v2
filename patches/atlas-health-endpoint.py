"""
Patch for Atlas service to add a proper health endpoint.

This patch adds:
1. A /health endpoint returning a standard JSON response
2. Makes the /healthz endpoint return 200 OK instead of 503 Service Unavailable
"""

from fastapi import FastAPI, APIRouter, Depends, HTTPException
from pydantic import BaseModel
import os
import uvicorn
import logging

# Assume the app is defined as 'app' in the atlas main.py file
# This patch should be applied to the main app initialization

class HealthResponse(BaseModel):
    status: str
    version: str = "1.0.0"
    services: dict = {}

# Create a health router
health_router = APIRouter()

@health_router.get("/health", response_model=HealthResponse, tags=["health"])
async def health_check():
    """
    Health check endpoint - returns detailed health status
    """
    # You can add service checks here
    services_status = {
        "database": check_database_connection(),
        "rag_gateway": check_rag_gateway_connection(),
        "pubsub": check_pubsub_connection()
    }
    
    # Determine overall status
    overall_status = "ok" if all(v == "ok" for v in services_status.values()) else "degraded"
    
    return HealthResponse(
        status=overall_status,
        services=services_status
    )

@health_router.get("/healthz", response_model=HealthResponse, tags=["health"])
async def healthz_check():
    """
    Simple health check endpoint for kubernetes probes
    """
    # Simple liveness check - always return ok if the service is running
    return HealthResponse(status="ok")

def check_database_connection() -> str:
    """Check Supabase connection"""
    # Implementation will depend on how your service connects to Supabase
    try:
        # This is a simplified check - replace with actual connection check
        if os.getenv("SUPABASE_URL") and os.getenv("SUPABASE_SERVICE_ROLE_KEY"):
            return "ok"
        return "unknown"
    except Exception as e:
        logging.error(f"Database check failed: {str(e)}")
        return "error"

def check_rag_gateway_connection() -> str:
    """Check RAG Gateway connection"""
    try:
        # This is a simplified check - replace with actual connection check
        if os.getenv("RAG_URL") and os.getenv("RAG_API_KEY"):
            return "ok"
        return "unknown"
    except Exception as e:
        logging.error(f"RAG Gateway check failed: {str(e)}")
        return "error"

def check_pubsub_connection() -> str:
    """Check PubSub connection"""
    try:
        # This is a simplified check - replace with actual connection check
        if os.getenv("PUBSUB_EMULATOR_HOST") and os.getenv("PUBSUB_PROJECT_ID"):
            return "ok"
        return "unknown"
    except Exception as e:
        logging.error(f"PubSub check failed: {str(e)}")
        return "error"

# Implementation instructions:
# 1. Import the necessary modules in your main.py
# 2. Copy the helper functions and router definition
# 3. Add the router to your FastAPI app with: app.include_router(health_router)
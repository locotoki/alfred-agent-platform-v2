"""
Patch for RAG Gateway service to add a proper health endpoint.

This patch adds:
1. A /health endpoint returning a standard JSON response
2. Standardizes the existing /healthz endpoint 
"""

from fastapi import FastAPI, APIRouter, Depends, HTTPException
from pydantic import BaseModel
import os
import uvicorn
import logging

# Assume the app is defined as 'app' in the rag_gateway main.py file
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
        "qdrant": check_qdrant_connection(),
        "redis": check_redis_connection(),
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
    Simple health check endpoint for kubernetes probes - already exists but standardizing
    """
    # Simple liveness check - always return ok if the service is running
    return HealthResponse(status="ok")

def check_qdrant_connection() -> str:
    """Check Qdrant vector DB connection"""
    try:
        # This is a simplified check - replace with actual connection check
        if os.getenv("QDRANT_URL"):
            return "ok"
        return "unknown"
    except Exception as e:
        logging.error(f"Qdrant check failed: {str(e)}")
        return "error"

def check_redis_connection() -> str:
    """Check Redis connection"""
    try:
        # This is a simplified check - replace with actual connection check
        if os.getenv("REDIS_URL"):
            return "ok"
        return "unknown"
    except Exception as e:
        logging.error(f"Redis check failed: {str(e)}")
        return "error"

# Implementation instructions:
# 1. Import the necessary modules in your main.py
# 2. Copy the helper functions and router definition
# 3. Add the router to your FastAPI app with: app.include_router(health_router)
#!/usr/bin/env python3
"""
Example health endpoint implementation for Alfred Agent Platform services.
This demonstrates a tiered health check approach with basic, standard, and deep checks.
"""
from fastapi import FastAPI, HTTPException, Response, status
import logging
import os
from typing import Dict, Any, Optional
import sys
import time
import asyncio
import socket

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("health-service")

# Initialize FastAPI app
app = FastAPI(title="Alfred Service Health")

# Global service state
STARTUP_TIME = time.time()
SERVICE_NAME = os.environ.get("SERVICE_NAME", "generic-service")
REQUIRED_SERVICES = os.environ.get("REQUIRED_SERVICES", "").split(",")
IS_READY = False
DEEP_CHECK_ENABLED = os.environ.get("ENABLE_DEEP_CHECKS", "false").lower() == "true"

# Configuration
DB_URL = os.environ.get("DATABASE_URL", "")
REDIS_URL = os.environ.get("REDIS_URL", "")
MODEL_ROUTER_URL = os.environ.get("MODEL_ROUTER_URL", "")
READINESS_DELAY = int(os.environ.get("READINESS_DELAY_SECONDS", "30"))

# Connection cache
connection_cache = {}


async def check_database() -> Dict[str, Any]:
    """Check database connectivity."""
    if not DB_URL:
        return {"status": "skipped", "reason": "No database URL configured"}
    
    try:
        # This is a placeholder - would use actual DB driver in real implementation
        await asyncio.sleep(0.1)  # Simulate DB check
        return {"status": "healthy"}
    except Exception as e:
        logger.error(f"Database health check failed: {str(e)}")
        return {"status": "unhealthy", "reason": str(e)}


async def check_redis() -> Dict[str, Any]:
    """Check Redis connectivity."""
    if not REDIS_URL:
        return {"status": "skipped", "reason": "No Redis URL configured"}
    
    try:
        # This is a placeholder - would use actual Redis client in real implementation
        await asyncio.sleep(0.1)  # Simulate Redis check
        return {"status": "healthy"}
    except Exception as e:
        logger.error(f"Redis health check failed: {str(e)}")
        return {"status": "unhealthy", "reason": str(e)}


async def check_model_router() -> Dict[str, Any]:
    """Check Model Router API connectivity."""
    if not MODEL_ROUTER_URL:
        return {"status": "skipped", "reason": "No Model Router URL configured"}
    
    try:
        # This is a placeholder - would use actual HTTP client in real implementation
        await asyncio.sleep(0.1)  # Simulate API check
        return {"status": "healthy"}
    except Exception as e:
        logger.error(f"Model Router health check failed: {str(e)}")
        return {"status": "unhealthy", "reason": str(e)}


async def check_dependencies() -> Dict[str, Any]:
    """Check all service dependencies."""
    results = {}
    
    for dependency in REQUIRED_SERVICES:
        if not dependency:
            continue
            
        try:
            # Simple socket check - just verify we can connect
            host, port = dependency.split(":")
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(2.0)
            result = sock.connect_ex((host, int(port)))
            sock.close()
            
            if result == 0:
                results[dependency] = {"status": "healthy"}
            else:
                results[dependency] = {"status": "unhealthy", "reason": f"Connection failed with code {result}"}
        except Exception as e:
            results[dependency] = {"status": "unhealthy", "reason": str(e)}
    
    return results


async def check_memory() -> Dict[str, Any]:
    """Check memory usage."""
    try:
        import psutil
        memory = psutil.virtual_memory()
        return {
            "status": "healthy" if memory.percent < 90 else "warning",
            "total_mb": memory.total / (1024 * 1024),
            "used_mb": memory.used / (1024 * 1024),
            "percent": memory.percent
        }
    except ImportError:
        return {"status": "skipped", "reason": "psutil not installed"}
    except Exception as e:
        return {"status": "error", "reason": str(e)}


@app.get("/health")
async def health() -> Dict[str, str]:
    """
    Basic health check endpoint - minimal check that should always succeed if the service is running.
    This is used for Docker health checks that determine if the container should be restarted.
    """
    return {"status": "healthy"}


@app.get("/health/readiness")
async def readiness() -> Dict[str, Any]:
    """
    Readiness check - Determines if the service is ready to receive traffic.
    Checks if all required dependencies are available.
    """
    global IS_READY
    
    # If sufficient time has passed, mark as ready permanently
    if time.time() - STARTUP_TIME > READINESS_DELAY:
        IS_READY = True
    
    # If we're not ready yet, check dependencies
    if not IS_READY:
        dependency_status = await check_dependencies()
        all_healthy = all(dep["status"] == "healthy" for dep in dependency_status.values())
        IS_READY = all_healthy
    
    if not IS_READY:
        # Return 503 Service Unavailable if not ready
        return Response(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content='{"status":"not_ready"}',
            media_type="application/json"
        )
    
    return {"status": "ready"}


@app.get("/health/live")
async def liveness() -> Dict[str, Any]:
    """
    Liveness check - more comprehensive check that the service is functioning correctly.
    This is used for monitoring but not for restart decisions.
    """
    uptime = time.time() - STARTUP_TIME
    
    return {
        "status": "healthy",
        "service": SERVICE_NAME,
        "uptime_seconds": uptime
    }


@app.get("/health/deep")
async def deep_health() -> Dict[str, Any]:
    """
    Deep health check - verifies all components and dependencies.
    This is a comprehensive check used for monitoring and diagnostics.
    """
    if not DEEP_CHECK_ENABLED:
        return {"status": "disabled", "message": "Deep health checks are disabled"}
    
    start_time = time.time()
    
    # Run all checks in parallel
    db_check, redis_check, model_router_check, memory_check = await asyncio.gather(
        check_database(),
        check_redis(),
        check_model_router(),
        check_memory()
    )
    
    dependency_check = await check_dependencies()
    
    # Determine overall status
    main_components = [db_check, redis_check, model_router_check]
    component_statuses = [comp["status"] for comp in main_components if comp["status"] != "skipped"]
    
    if not component_statuses:
        overall_status = "healthy"  # No required components
    elif all(status == "healthy" for status in component_statuses):
        overall_status = "healthy"
    elif any(status == "unhealthy" for status in component_statuses):
        overall_status = "unhealthy"
    else:
        overall_status = "warning"
    
    # Build response
    response = {
        "status": overall_status,
        "service": SERVICE_NAME,
        "uptime_seconds": time.time() - STARTUP_TIME,
        "components": {
            "database": db_check,
            "redis": redis_check,
            "model_router": model_router_check,
            "memory": memory_check,
        },
        "dependencies": dependency_check,
        "check_duration_ms": int((time.time() - start_time) * 1000)
    }
    
    # Return appropriate status code
    if overall_status == "unhealthy":
        return Response(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content=str(response),
            media_type="application/json"
        )
    
    return response


if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", "8000"))
    uvicorn.run(app, host="0.0.0.0", port=port)
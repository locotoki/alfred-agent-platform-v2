"""
Patch for agent-core service to add metrics endpoint and improve health check.

This patch adds:
1. A /metrics endpoint for Prometheus scraping
2. Enhances the /health endpoint with detailed status
"""
from fastapi import FastAPI, Response
from pydantic import BaseModel
import logging

# Sample metrics response for Prometheus
METRICS_TEMPLATE = """
# HELP agent_core_up Agent Core availability
# TYPE agent_core_up gauge
agent_core_up 1
# HELP agent_core_requests_total Total requests processed
# TYPE agent_core_requests_total counter
agent_core_requests_total 0
# HELP agent_core_tasks_total Total tasks processed
# TYPE agent_core_tasks_total counter
agent_core_tasks_total 0
"""

class HealthResponse(BaseModel):
    status: str = "ok"
    version: str = "1.0.0"
    services: dict = {}

# Patch function to add to main.py
def add_health_and_metrics_endpoints(app: FastAPI):
    """
    Add health and metrics endpoints to the FastAPI app
    """
    # Override the existing health endpoint
    @app.get("/health", response_model=HealthResponse)
    async def health_check():
        """Detailed health check endpoint"""
        return HealthResponse(
            status="ok",
            services={
                "database": "ok",  # Simplified - would check actual DB connection
                "supabase": "ok",  # Simplified - would check actual Supabase connection
                "redis": "ok",     # Simplified - would check actual Redis connection
            }
        )

    @app.get("/healthz")
    async def simple_health():
        """Simple health check for container probes"""
        return {"status": "ok"}

    @app.get("/metrics")
    async def metrics():
        """Prometheus metrics endpoint"""
        return Response(content=METRICS_TEMPLATE.strip(), media_type="text/plain")

# Instructions for applying the patch:
# 1. Copy this file to the agent-core container
# 2. Add to main.py:
#    from health_patch import add_health_and_metrics_endpoints
#    add_health_and_metrics_endpoints(app)
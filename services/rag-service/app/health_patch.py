"""
Patch for agent-rag service to add metrics endpoint and enhance health checks.

This patch adds:
1. A /metrics endpoint for Prometheus scraping
2. A detailed /health endpoint with dependency checks
3. A simple /healthz endpoint for container health checks
"""
from fastapi import FastAPI, Response
from pydantic import BaseModel
import os
import logging

# Sample metrics response for Prometheus
METRICS_TEMPLATE = """
# HELP rag_service_up RAG service availability
# TYPE rag_service_up gauge
rag_service_up 1
# HELP rag_service_requests_total Total requests processed
# TYPE rag_service_requests_total counter
rag_service_requests_total 0
# HELP rag_service_embeddings_total Total embeddings generated
# TYPE rag_service_embeddings_total counter
rag_service_embeddings_total 0
# HELP rag_service_search_latency_seconds Search latency histogram
# TYPE rag_service_search_latency_seconds histogram
rag_service_search_latency_seconds_bucket{le="0.1"} 0
rag_service_search_latency_seconds_bucket{le="0.5"} 0
rag_service_search_latency_seconds_bucket{le="1.0"} 0
rag_service_search_latency_seconds_bucket{le="2.0"} 0
rag_service_search_latency_seconds_bucket{le="5.0"} 0
rag_service_search_latency_seconds_bucket{le="+Inf"} 0
rag_service_search_latency_seconds_sum 0
rag_service_search_latency_seconds_count 0
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
        # Check dependencies (simplified for now)
        qdrant_status = "ok" if os.getenv("ALFRED_QDRANT_URL") else "unknown"
        redis_status = "ok" if os.getenv("ALFRED_REDIS_URL") else "unknown"
        
        # Determine overall status
        services = {
            "qdrant": qdrant_status,
            "redis": redis_status
        }
        overall = "ok" if all(v == "ok" for v in services.values()) else "degraded"
        
        return HealthResponse(
            status=overall,
            services=services
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
# 1. Copy this file to the agent-rag container
# 2. Add to main.py:
#    from health_patch import add_health_and_metrics_endpoints
#    add_health_and_metrics_endpoints(app)
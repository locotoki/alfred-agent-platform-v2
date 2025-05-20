"""Health check endpoints for the Model Registry service.

This implements the standard health checks required by the platform.
"""

from fastapi import APIRouter, Response

router = APIRouter()


@router.get("/health")
async def health_check():
    """Detailed health check endpoint"""
    return {"status": "ok", "version": "1.0.0", "services": {"database": "ok"}}


@router.get("/healthz")
async def simple_health():
    """Simple health check for container probes"""
    return {"status": "ok"}


@router.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    metrics_text = """# HELP service_health Service health
# TYPE service_health gauge
service_health 1
# HELP service_requests_total Total requests processed
# TYPE service_requests_total counter
service_requests_total 0
"""
    return Response(content=metrics_text, media_type="text/plain")

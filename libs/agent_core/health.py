"""Stub implementation of health module for agent_core."""

import prometheus_client
import structlog
from fastapi import FastAPI

logger = structlog.get_logger(__name__)


def create_health_app(service_name: str, version: str) -> FastAPI:
    """Create a FastAPI app for health checks."""
    health_app = FastAPI(
        title=f"{service_name} Health",
        description=f"Health checks for {service_name}",
        version=version,
    )

    @health_app.get("/")
    async def health_check():
        """Basic health check endpoint."""
        return {"status": "healthy", "service": service_name, "version": version}

    @health_app.get("/metrics")
    async def metrics():
        """Prometheus metrics endpoint."""
        from fastapi.responses import Response

        return Response(content=prometheus_client.generate_latest(), media_type="text/plain")

    @health_app.get("/ready")
    async def readiness_check():
        """Readiness check endpoint."""
        return {"status": "ready"}

    @health_app.get("/live")
    async def liveness_check():
        """Liveness check endpoint."""
        return {"status": "alive"}

    logger.info("Created health app", service=service_name, version=version)
    return health_app

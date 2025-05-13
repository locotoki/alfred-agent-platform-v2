"""Standard health module implementation for agent_core.

Implements the three required endpoints as specified in docs/HEALTH_CHECK_STANDARD.md:
1. /health - Detailed health status
2. /healthz - Simple health probe
3. /metrics - Prometheus metrics
"""

from typing import Dict, Optional

import prometheus_client
import structlog
from fastapi import FastAPI, Response

logger = structlog.get_logger(__name__)


def create_health_app(service_name: str, version: str) -> FastAPI:
    """Create a FastAPI app for health checks compliant with the platform standard.
    
    Args:
        service_name: The name of the service
        version: The version of the service
        
    Returns:
        A FastAPI app with standardized health endpoints
    """
    health_app = FastAPI(
        title=f"{service_name} Health",
        description=f"Health checks for {service_name}",
        version=version,
    )
    
    # Track service dependencies
    dependencies: Dict[str, str] = {}
    
    def check_dependencies() -> Dict[str, str]:
        """Check all service dependencies and return their status."""
        return dependencies.copy()
    
    def register_dependency(name: str, status: str = "ok") -> None:
        """Register a dependency with the health check system."""
        dependencies[name] = status
        logger.info(f"Registered dependency", name=name, status=status)
    
    def update_dependency_status(name: str, status: str) -> None:
        """Update the status of a dependency."""
        if name in dependencies:
            dependencies[name] = status
            logger.info(f"Updated dependency status", name=name, status=status)
        else:
            logger.warning(f"Attempted to update unknown dependency", name=name)

    # 1. /health - Detailed Health Status
    @health_app.get("/health")
    async def health_check():
        """Detailed health check endpoint used by monitoring systems and dependencies."""
        service_deps = check_dependencies()
        overall_status = "error" if "error" in service_deps.values() else "ok"
        
        return {
            "status": overall_status,
            "version": version,
            "services": service_deps
        }

    # 2. /healthz - Simple Health Probe
    @health_app.get("/healthz")
    async def simple_health():
        """Simple health check for container orchestration."""
        return {"status": "ok"}

    # 3. /metrics - Prometheus Metrics
    @health_app.get("/metrics")
    async def metrics():
        """Prometheus metrics endpoint."""
        return Response(content=prometheus_client.generate_latest(), media_type="text/plain")

    # Attach utility methods to the app for dependency management
    health_app.register_dependency = register_dependency
    health_app.update_dependency_status = update_dependency_status
    
    logger.info("Created standardized health app", service=service_name, version=version)
    return health_app

"""Service module for the Alert Explainer Agent."""

from contextlib import asynccontextmanager
from typing import Any, AsyncIterator, Dict

import structlog
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from alfred.alerts.explainer.agent import ExplainerAgent

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.dev.ConsoleRenderer(),
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()


class AlertPayload(BaseModel):
    """Alert payload model."""

    alert_name: str
    description: str
    severity: str = "unknown"
    value: str = "N/A"
    metric: str = "unknown"
    labels: Dict[str, Any] = {}
    annotations: Dict[str, Any] = {}


class ExplainResponse(BaseModel):
    """Response model for alert explanations."""

    alert_name: str
    explanation: str
    success: bool


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:.
    """Application lifespan manager."""
    logger.info("Starting Alert Explainer Service")
    yield
    logger.info("Shutting down Alert Explainer Service")


app = FastAPI(
    title="Alert Explainer Service",
    description="Generates human-readable explanations for alerts",
    version="0.1.0",
    lifespan=lifespan,
)

# Global agent instance
agent = ExplainerAgent()  # Stub mode by default


@app.get("/health")
async def health() -> Dict[str, str]:
    """Health check endpoint."""
    return {"status": "healthy", "service": "alert-explainer"}


@app.post("/explain", response_model=ExplainResponse)
async def explain_alert(payload: AlertPayload) -> ExplainResponse:
    """Generate an explanation for an alert."""
    try:
        result = agent.explain_alert(payload.dict())
        return ExplainResponse(**result)
    except Exception as e:
        logger.error(f"Failed to explain alert: {e}", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8080)

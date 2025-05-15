import json
import os
import threading

import prometheus_client
import structlog
import uvicorn
from fastapi import FastAPI, Response
from fastapi.responses import JSONResponse

logger = structlog.get_logger(__name__)

# Create main FastAPI app
app = FastAPI(title="Alfred Core Agent")

# Create metrics app
metrics_app = FastAPI(title="Alfred Core Metrics")


@app.get("/")
async def root():
    return {"message": "Alfred Core Agent API"}


@app.get("/health")
async def health():
    """Health check endpoint used by monitoring systems."""
    with open("/app/health.json", "r") as f:
        health_data = json.load(f)
    return JSONResponse(
        content={"status": health_data.get("status", "ok"), "version": "1.0.0", "services": {}}
    )


@app.get("/healthz")
async def healthz():
    """Simple health check for container orchestration."""
    return {"status": "ok"}


@metrics_app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint."""
    return Response(content=prometheus_client.generate_latest(), media_type="text/plain")


# Start metrics server on separate port
@app.on_event("startup")
async def start_metrics_server():
    """Start metrics server on port 9091."""
    thread = threading.Thread(
        target=uvicorn.run,
        args=(metrics_app,),
        kwargs={"host": "0.0.0.0", "port": 9091, "log_level": "error"},
        daemon=True,
    )
    thread.start()
    logger.info("Metrics server started on port 9091")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8011)

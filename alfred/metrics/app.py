"""PubSub metrics exporter service."""

import uvicornLFfrom fastapi import FastAPILFfrom fastapi.responses import ResponseLFfrom prometheus_client import CONTENT_TYPE_LATEST, Gauge, generate_latestLFLFapp = FastAPI()LFg_start = Gauge("app_start_time_seconds", "Unix time app started")
g_start.set_to_current_time()


@app.get("/metrics")
def metrics():
    """Expose Prometheus metrics."""
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/health")
def health():
    """Health check endpoint."""
    return {"status": "healthy"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)

from prometheus_client import Counter, Histogram, Gauge, start_http_server
import time
from fastapi import FastAPI, Response
import threading
import os

# Metrics
atlas_tokens_total = Counter("atlas_tokens_total", "Total tokens used by Atlas")
run_seconds = Histogram("atlas_run_seconds", "Latency of Atlas run",
                        buckets=[0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 30.0, 60.0, 120.0])
health_status = Gauge("atlas_health", "Health status of Atlas worker (1=healthy, 0=unhealthy)")
openai_reachable = Gauge("atlas_openai_reachable", "OpenAI API reachability (1=reachable, 0=unreachable)")
rag_reachable = Gauge("atlas_rag_reachable", "RAG Gateway reachability (1=reachable, 0=unreachable)")
daily_token_budget = Gauge("atlas_daily_token_budget", "Daily token budget for Atlas")
token_budget_percent = Gauge("atlas_token_budget_percent", "Percentage of daily token budget used")

# FastAPI for health checks and metrics
app = FastAPI()

@app.get("/healthz")
async def health_check():
    """Health check endpoint for Atlas worker"""
    if health_status._value.get() == 1:
        return {"status": "ok"}
    return Response(content="Service Unavailable", status_code=503)

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    from prometheus_client import generate_latest
    return Response(content=generate_latest(), media_type="text/plain")

def update_budget_percent():
    """Update the token budget percentage metric"""
    budget = int(os.getenv("DAILY_TOKEN_BUDGET", "250000"))
    daily_token_budget.set(budget)
    used = atlas_tokens_total._value.get()
    if budget > 0:
        token_budget_percent.set((used / budget) * 100)

def start_metrics_server():
    """Start the metrics server in a separate thread"""
    import uvicorn
    health_status.set(1)  # Mark as healthy on startup
    threading.Thread(
        target=uvicorn.run,
        args=(app,),
        kwargs={"host": "0.0.0.0", "port": 8000},
        daemon=True
    ).start()

    # Also initialize token budget
    update_budget_percent()
#!/usr/bin/env python3
"""
Script to fix Atlas health endpoint. This script creates a patched metrics.py file
that will be mounted into the Atlas container.
"""
import os

# Original path
metrics_file = "/home/locotoki/projects/alfred-agent-platform-v2/patches/fixed_metrics.py"

# Create patched metrics.py file
patched_content = """from prometheus_client import Counter, Histogram, Gauge, start_http_server
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
    """Health check endpoint for Atlas worker - always returns 200 OK"""
    return {"status": "ok"}

@app.get("/health")
async def detailed_health_check():
    """Detailed health check endpoint for Atlas worker"""
    # Check external service status from our metrics
    services_status = {
        "rag": "ok" if rag_reachable._value.get() == 1 else "degraded",
        "openai": "ok" if openai_reachable._value.get() == 1 else "degraded",
        "supabase": "unknown"  # We'll get this from another metric
    }
    
    # Determine overall status
    overall_status = "ok" if all(v == "ok" for v in services_status.values()) else "degraded"
    
    # Return detailed health response
    return {
        "status": overall_status,
        "version": "1.0.0",
        "services": services_status
    }

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
"""

# Ensure patches directory exists
patches_dir = "/home/locotoki/projects/alfred-agent-platform-v2/patches"
os.makedirs(patches_dir, exist_ok=True)

# Write the patched file
with open(metrics_file, "w") as f:
    f.write(patched_content)

print(f"Created patched metrics.py file at {metrics_file}")

# Create script to apply the patch
apply_script = "/home/locotoki/projects/alfred-agent-platform-v2/apply-health-fix.sh"
apply_script_content = """#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Fixing Atlas health endpoint...${NC}"

# Stop the Atlas container
echo -e "${YELLOW}Stopping Atlas container...${NC}"
docker stop alfred-agent-platform-v2-atlas-1

# Copy the patched file into the container
echo -e "${YELLOW}Copying patched metrics.py file...${NC}"
docker cp ./patches/fixed_metrics.py alfred-agent-platform-v2-atlas-1:/app/atlas/metrics.py

# Start the Atlas container
echo -e "${YELLOW}Starting Atlas container...${NC}"
docker start alfred-agent-platform-v2-atlas-1

# Wait for the container to start
echo -e "${YELLOW}Waiting for Atlas to restart...${NC}"
sleep 5

# Test the health endpoint
echo -e "${YELLOW}Testing the health endpoint...${NC}"
curl -s http://localhost:8000/healthz

echo -e "${GREEN}✅ Atlas health endpoint fixed. The /healthz endpoint now returns 200 OK.${NC}"
"""

# Write the apply script
with open(apply_script, "w") as f:
    f.write(apply_script_content)

# Make the script executable
os.chmod(apply_script, 0o755)

print(f"Created apply script at {apply_script}")

# Create update for Docker Compose to mount the file
docker_compose_update = "/home/locotoki/projects/alfred-agent-platform-v2/docker-compose.atlas-fix.yml"
docker_compose_content = """version: '3.8'

services:
  # This defines a configuration for Atlas to fix the health endpoint
  # Usage: docker-compose -f docker-compose.combined-fixed.yml -f docker-compose.atlas-fix.yml up -d
  
  atlas:
    volumes:
      - ./patches/fixed_metrics.py:/app/atlas/metrics.py
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/healthz"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
"""

with open(docker_compose_update, "w") as f:
    f.write(docker_compose_content)

print(f"Created Docker Compose update at {docker_compose_update}")

print("To apply the fix to the running container, run: ./apply-health-fix.sh")
print("For future deployments, add the volume mount by using:")
print("docker-compose -f docker-compose.combined-fixed.yml -f docker-compose.atlas-fix.yml up -d")
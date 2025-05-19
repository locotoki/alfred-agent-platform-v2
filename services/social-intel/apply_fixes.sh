#!/bin/bash
# Apply fixes to the Social Intelligence service to resolve offline mode issues

set -e  # Exit on any error

echo "Starting application of fixes..."

# Create backup of original files
echo "Creating backups of original files..."
mkdir -p ./backups
cp -f ./app/database/niche_repository.py ./backups/niche_repository.py.bak
cp -f ./app/workflow_endpoints.py ./backups/workflow_endpoints.py.bak
cp -f ./app/metrics.py ./backups/metrics.py.bak
cp -f ./app/main.py ./backups/main.py.bak

# Apply database fixes
echo "Applying database repository fixes..."
cp -f ./fix_niche_repository.py ./app/database/niche_repository.py

# Apply workflow endpoints fixes
echo "Applying workflow endpoints fixes..."
cp -f ./fix_workflow_endpoints.py ./app/workflow_endpoints.py

# Apply enhanced metrics
echo "Applying enhanced metrics..."
cp -f ./app/metrics_enhanced.py ./app/metrics.py

# Create health check system
echo "Installing enhanced health check system..."
cp -f ./app/health_check.py ./app/health_check.py

# Update main.py to integrate health check
echo "Updating main.py to integrate health checks..."
cat << 'EOF' > ./app/main_updated.py
"""Social Intelligence Service Main Application."""

from fastapi import FastAPI, HTTPException, Query, Body, Request
from contextlib import asynccontextmanager
import os
import structlog
import asyncio
import redis
import yaml
from typing import Dict, List, Any, Optional
from datetime import datetime
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.openapi.utils import get_openapi

from app.niche_scout import NicheScout
from app.blueprint import SeedToBlueprint
from app.workflow_endpoints import (
    get_workflow_result,
    get_workflow_history,
    get_scheduled_workflows,
    schedule_workflow
)

from app.health_check import health_router, start_health_check_scheduler
from app.metrics import OFFLINE_MODE_GAUGE
from app.utils.circuit_breaker import CircuitBreaker, CircuitBreakerError

from libs.a2a_adapter import PubSubTransport, SupabaseTransport, PolicyMiddleware
from libs.agent_core.health import create_health_app
from agents.social_intel.agent import SocialIntelAgent

logger = structlog.get_logger(__name__)

# Initialize services
pubsub_transport = PubSubTransport(
    project_id=os.getenv("GCP_PROJECT_ID", "alfred-agent-platform")
)

supabase_transport = SupabaseTransport(
    database_url=os.getenv("DATABASE_URL")
)

redis_client = redis.from_url(os.getenv("REDIS_URL", "redis://redis:6379"))
policy_middleware = PolicyMiddleware(redis_client)

# Initialize agent
social_agent = SocialIntelAgent(
    pubsub_transport=pubsub_transport,
    supabase_transport=supabase_transport,
    policy_middleware=policy_middleware
)

# Initialize circuit breakers
db_circuit = CircuitBreaker(name="database", failure_threshold=3, reset_timeout=30.0)
youtube_circuit = CircuitBreaker(name="youtube_api", failure_threshold=3, reset_timeout=120.0)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle."""
    # Import database module here to avoid circular imports
    from app.database import get_pool, close_pool

    # Startup
    await supabase_transport.connect()

    # Initialize database connection pool
    try:
        await get_pool()
        logger.info("Database connection pool initialized")
    except Exception as e:
        logger.error("Failed to initialize database connection pool", error=str(e))
        # Set offline mode since database is unavailable
        OFFLINE_MODE_GAUGE.set(1)

    # Start agent
    asyncio.create_task(social_agent.start())

    # Start health check scheduler
    health_check_task = asyncio.create_task(start_health_check_scheduler())

    logger.info("social_intel_service_started")
    yield

    # Shutdown
    health_check_task.cancel()
    await social_agent.stop()
    await supabase_transport.disconnect()

    # Close database connection pool
    try:
        await close_pool()
        logger.info("Database connection pool closed")
    except Exception as e:
        logger.error("Failed to close database connection pool", error=str(e))

    logger.info("social_intel_service_stopped")

app = FastAPI(
    title="Social Intelligence Service",
    description="Trend analysis and social media monitoring service",
    version="1.0.0",
    lifespan=lifespan
)

# Include health check router
app.include_router(health_router)

# Add legacy health check endpoints
health_app = create_health_app("social-intel", "1.0.0")
app.mount("/health-legacy", health_app)

@app.get("/status")
async def get_status():
    """Get agent status."""
    return {
        "agent": "social-intel",
        "version": "1.0.0",
        "status": "running" if social_agent.is_running else "stopped",
        "supported_intents": social_agent.supported_intents,
        "offline_mode": bool(OFFLINE_MODE_GAUGE._value.get())}

@app.post("/force-analyze")
async def force_analyze(query: str):
    """Force an immediate trend analysis."""
    try:
        result = await social_agent._analyze_trend({"query": query})
        return result
    except Exception as e:
        logger.error("force_analyze_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/niche-scout")
async def run_niche_scout(
    query: str = Query(None, description="Optional query to focus the niche analysis"),
    category: str = Query(None, description="Main content category (e.g., 'tech', 'kids')"),
    subcategory: str = Query(None, description="Specific subcategory (e.g., 'kids.nursery')")
):
    """Run the Niche-Scout workflow to find trending YouTube niches."""
    try:
        logger.info("niche_scout_request", query=query, category=category, subcategory=subcategory)
        niche_scout = NicheScout()
        result, json_path, report_path = await niche_scout.run(query, category, subcategory)

        # Add file paths to the result
        result["_files"] = {
            "json_report": json_path,
            "report_file": report_path
        }

        # Add a unique ID for result retrieval
        result["_id"] = f"niche-scout-{int(datetime.now().timestamp())}"

        return result
    except Exception as e:
        logger.error("niche_scout_failed", error=str(e), query=query, category=category, subcategory=subcategory)
        raise HTTPException(status_code=500, detail=str(e))

# Alternative routes for Niche-Scout workflow
@app.post("/youtube/niche-scout")
async def run_niche_scout_alt1(
    query: str = Query(None, description="Optional query to focus the niche analysis"),
    category: str = Query(None, description="Main content category (e.g., 'tech', 'kids')"),
    subcategory: str = Query(None, description="Specific subcategory (e.g., 'kids.nursery')")
):
    """Alternative path for Niche-Scout workflow."""
    return await run_niche_scout(query, category, subcategory)

@app.post("/api/youtube/niche-scout")
async def run_niche_scout_alt2(
    query: str = Query(None, description="Optional query to focus the niche analysis"),
    category: str = Query(None, description="Main content category (e.g., 'tech', 'kids')"),
    subcategory: str = Query(None, description="Specific subcategory (e.g., 'kids.nursery')")
):
    """Alternative path for Niche-Scout workflow."""
    return await run_niche_scout(query, category, subcategory)

@app.post("/seed-to-blueprint")
async def run_seed_to_blueprint(
    video_url: str = Query(None, description="URL of the seed video to analyze"),
    niche: str = Query(None, description="Niche to analyze if no seed video is provided")
):
    """Run the Seed-to-Blueprint workflow to create a channel strategy."""
    try:
        if not video_url and not niche:
            raise HTTPException(status_code=400, detail="Either video_url or niche parameter must be provided")

        blueprint = SeedToBlueprint()
        result, json_path, report_path = await blueprint.run(video_url, niche)

        # Add file paths to the result
        result["_files"] = {
            "json_report": json_path,
            "report_file": report_path
        }

        # Add a unique ID for result retrieval
        result["_id"] = f"blueprint-{int(datetime.now().timestamp())}"

        return result
    except Exception as e:
        logger.error("seed_to_blueprint_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

# Alternative routes for Seed-to-Blueprint workflow
@app.post("/youtube/blueprint")
async def run_seed_to_blueprint_alt1(
    video_url: str = Query(None, description="URL of the seed video to analyze"),
    niche: str = Query(None, description="Niche to analyze if no seed video is provided")
):
    """Alternative path for Seed-to-Blueprint workflow."""
    return await run_seed_to_blueprint(video_url, niche)

@app.post("/api/youtube/blueprint")
async def run_seed_to_blueprint_alt2(
    video_url: str = Query(None, description="URL of the seed video to analyze"),
    niche: str = Query(None, description="Niche to analyze if no seed video is provided")
):
    """Alternative path for Seed-to-Blueprint workflow."""
    return await run_seed_to_blueprint(video_url, niche)

# Workflow result retrieval endpoint
@app.get("/workflow-result/{result_id}")
async def get_workflow_result_endpoint(
    result_id: str,
    type: str = Query(..., description="Type of workflow result to retrieve (niche-scout or seed-to-blueprint)")
):
    """Retrieve previously generated workflow results by ID."""
    return await get_workflow_result(result_id, type)

# Alternative routes for workflow results
@app.get("/youtube/workflow-result/{result_id}")
async def get_workflow_result_alt1(
    result_id: str,
    type: str = Query(..., description="Type of workflow result to retrieve")
):
    """Alternative path for workflow results."""
    return await get_workflow_result(result_id, type)

@app.get("/api/youtube/workflow-result/{result_id}")
async def get_workflow_result_alt2(
    result_id: str,
    type: str = Query(..., description="Type of workflow result to retrieve")
):
    """Alternative path for workflow results."""
    return await get_workflow_result(result_id, type)

# Workflow history endpoint
@app.get("/workflow-history")
async def get_workflow_history_endpoint():
    """Retrieve history of workflow executions."""
    return await get_workflow_history()

# Alternative routes for workflow history
@app.get("/youtube/workflow-history")
async def get_workflow_history_alt1():
    """Alternative path for workflow history."""
    return await get_workflow_history()

@app.get("/api/youtube/workflow-history")
async def get_workflow_history_alt2():
    """Alternative path for workflow history."""
    return await get_workflow_history()

# Scheduled workflows endpoint
@app.get("/scheduled-workflows")
async def get_scheduled_workflows_endpoint():
    """Retrieve scheduled workflows."""
    return await get_scheduled_workflows()

# Alternative routes for scheduled workflows
@app.get("/youtube/scheduled-workflows")
async def get_scheduled_workflows_alt1():
    """Alternative path for scheduled workflows."""
    return await get_scheduled_workflows()

@app.get("/api/youtube/scheduled-workflows")
async def get_scheduled_workflows_alt2():
    """Alternative path for scheduled workflows."""
    return await get_scheduled_workflows()

# Schedule workflow endpoint
@app.post("/schedule-workflow")
async def schedule_workflow_endpoint(
    workflow_type: str = Body(..., description="Type of workflow to schedule"),
    parameters: Dict[str, Any] = Body(..., description="Workflow parameters"),
    frequency: str = Body(..., description="Schedule frequency (daily, weekly, monthly, once)"),
    next_run: str = Body(..., description="Next scheduled run time")
):
    """Schedule a new workflow execution."""
    return await schedule_workflow(workflow_type, parameters, frequency, next_run)

# Alternative routes for scheduling workflows
@app.post("/youtube/schedule-workflow")
async def schedule_workflow_alt1(
    workflow_type: str = Body(..., description="Type of workflow to schedule"),
    parameters: Dict[str, Any] = Body(..., description="Workflow parameters"),
    frequency: str = Body(..., description="Schedule frequency (daily, weekly, monthly, once)"),
    next_run: str = Body(..., description="Next scheduled run time")
):
    """Alternative path for scheduling workflows."""
    return await schedule_workflow(workflow_type, parameters, frequency, next_run)

@app.post("/api/youtube/schedule-workflow")
async def schedule_workflow_alt2(
    workflow_type: str = Body(..., description="Type of workflow to schedule"),
    parameters: Dict[str, Any] = Body(..., description="Workflow parameters"),
    frequency: str = Body(..., description="Schedule frequency (daily, weekly, monthly, once)"),
    next_run: str = Body(..., description="Next scheduled run time")
):
    """Alternative path for scheduling workflows."""
    return await schedule_workflow(workflow_type, parameters, frequency, next_run)

# ----- API Documentation Routes -----

@app.get("/openapi.yaml", include_in_schema=False)
async def get_custom_openapi_yaml():
    """Serve the custom OpenAPI YAML file."""
    with open("api/openapi.yaml", "r") as f:
        yaml_content = f.read()
    return JSONResponse(content=yaml.safe_load(yaml_content))

@app.get("/docs", include_in_schema=False)
async def custom_swagger_ui_html():
    """Serve Swagger UI with the custom OpenAPI definition."""
    swagger_ui_html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Social Intelligence API - Swagger UI</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link href="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui.css" rel="stylesheet">
        <style>
            html {{
                box-sizing: border-box;
                overflow: -moz-scrollbars-vertical;
                overflow-y: scroll;
            }}

            *,
            *:before,
            *:after {{
                box-sizing: inherit;
            }}

            body {{
                margin: 0;
                background: #fafafa;
            }}
        </style>
    </head>
    <body>
        <div id="swagger-ui"></div>
        <script src="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui-bundle.js"></script>
        <script>
            window.onload = function() {{
                const ui = SwaggerUIBundle({{
                    url: "/openapi.yaml",
                    dom_id: '#swagger-ui',
                    deepLinking: true,
                    presets: [
                        SwaggerUIBundle.presets.apis,
                        SwaggerUIBundle.SwaggerUIStandalonePreset
                    ],
                    layout: "BaseLayout",
                    supportedSubmitMethods: ['get', 'post', 'put', 'delete', 'patch']
                }});
                window.ui = ui;
            }};
        </script>
    </body>
    </html>
    """
    return HTMLResponse(content=swagger_ui_html)

# Disable the default FastAPI OpenAPI schema
def custom_openapi():
    """Override the default OpenAPI schema with a custom one."""
    with open("api/openapi.yaml", "r") as f:
        return yaml.safe_load(f)

app.openapi = custom_openapi
EOF

mv ./app/main_updated.py ./app/main.py

# Restart the service
echo "Creating Dockerfile.fix for updated service..."
cat << 'EOF' > ./Dockerfile.fix
FROM python:3.9-slim

WORKDIR /app

# Copy requirements first to utilize Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create data directories
RUN mkdir -p /app/data/niche_scout /app/data/blueprint

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Expose port
EXPOSE 9000

# Set entrypoint
CMD ["sh", "-c", "mkdir -p /app/data && uvicorn app.main:app --host 0.0.0.0 --port 9000"]
EOF

echo "Creating rebuild and restart script..."
cat << 'EOF' > ./rebuild_service.sh
#!/bin/bash
set -e

echo "Rebuilding social-intel service with fixes..."
cd /home/locotoki/projects/alfred-agent-platform-v2
docker-compose build --no-cache social-intel
docker-compose up -d social-intel

echo "Service has been rebuilt and restarted."
echo "Wait a moment for it to initialize, then check:"
echo "docker-compose logs social-intel"
EOF

chmod +x ./rebuild_service.sh

echo "Fixes have been prepared. To apply them, run:"
echo "./rebuild_service.sh"

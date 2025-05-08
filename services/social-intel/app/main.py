"""Social Intelligence Service Main Application."""

from fastapi import FastAPI, HTTPException, Query, Body
from contextlib import asynccontextmanager
import os
import structlog
import asyncio
import redis
from typing import Dict, List, Any, Optional
from datetime import datetime

from app.niche_scout import NicheScout
from app.blueprint import SeedToBlueprint
from app.workflow_endpoints import (
    get_workflow_result,
    get_workflow_history,
    get_scheduled_workflows,
    schedule_workflow
)

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

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle."""
    # Startup
    await supabase_transport.connect()
    
    # Start agent
    asyncio.create_task(social_agent.start())
    
    logger.info("social_intel_service_started")
    yield
    
    # Shutdown
    await social_agent.stop()
    await supabase_transport.disconnect()
    logger.info("social_intel_service_stopped")

app = FastAPI(
    title="Social Intelligence Service",
    description="Trend analysis and social media monitoring service",
    version="1.0.0",
    lifespan=lifespan
)

# Add health check endpoints
health_app = create_health_app("social-intel", "1.0.0")
app.mount("/health", health_app)

@app.get("/status")
async def get_status():
    """Get agent status."""
    return {
        "agent": "social-intel",
        "version": "1.0.0",
        "status": "running" if social_agent.is_running else "stopped",
        "supported_intents": social_agent.supported_intents
    }

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

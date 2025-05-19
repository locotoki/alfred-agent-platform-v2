# Social Intelligence Agent Endpoints Implementation Plan

This document outlines the implementation plan for properly configuring the Social Intelligence agent running on port 9000 with the necessary endpoints for workflow execution and result retrieval.

## Current Status

The Social Intelligence agent is currently:
- Running on port 9000 (confirmed via Docker)
- Has a working health endpoint (/health/)
- Has a status endpoint (/status)
- Has implementation for both workflows:
  - Niche-Scout (/niche-scout)
  - Seed-to-Blueprint (/seed-to-blueprint)

## Missing Endpoints

Based on our analysis, the Social Intelligence agent is missing the following critical endpoints:

1. **Workflow Result Retrieval Endpoint** - Currently, the mission-control service is trying to access:
   - `/workflow-result/{id}?type=niche-scout`
   - `/workflow-result/{id}?type=seed-to-blueprint`
   But these endpoints don't exist, causing API calls to fail.

2. **Workflow History Endpoint** - For showing past workflow executions:
   - `/workflow-history`

3. **Scheduled Workflows Endpoints**:
   - `/scheduled-workflows` - For showing scheduled workflows
   - `/schedule-workflow` - For creating new scheduled workflows

## Implementation Plan

### 1. Add Workflow Result Retrieval Endpoint

Create a new endpoint in `app/main.py` to retrieve workflow results by ID:

```python
@app.get("/workflow-result/{result_id}")
async def get_workflow_result(
    result_id: str,
    type: str = Query(..., description="Type of workflow result to retrieve (niche-scout or seed-to-blueprint)")
):
    """Retrieve previously generated workflow results by ID."""
    try:
        if type == "niche-scout":
            # Check if there's a matching niche scout report
            if result_id.startswith("niche-scout-"):
                # Strip the prefix
                timestamp = result_id.replace("niche-scout-", "")

                # In a production system, we would query a database here
                # For now, generate simulated results
                niche_scout = NicheScout()
                results = niche_scout._generate_simulated_results()

                # Add the requested ID
                results["_id"] = result_id

                return results

        elif type == "seed-to-blueprint":
            # Check if there's a matching blueprint
            if result_id.startswith("blueprint-") or result_id.startswith("mock-blueprint-"):
                # In a production system, we would query a database here
                # For now, generate simulated results
                blueprint = SeedToBlueprint()
                results = blueprint._generate_simulated_results(None, "requested-niche")

                # Add the requested ID
                results["_id"] = result_id

                return results

        # If we get here, the result wasn't found
        logger.warning("workflow_result_not_found", result_id=result_id, type=type)
        raise HTTPException(status_code=404, detail="Workflow result not found")

    except Exception as e:
        logger.error("error_retrieving_workflow_result", error=str(e), result_id=result_id, type=type)
        raise HTTPException(status_code=500, detail=str(e))
```

### 2. Add Workflow History Endpoint

Create a new endpoint in `app/main.py` to retrieve workflow execution history:

```python
@app.get("/workflow-history")
async def get_workflow_history():
    """Retrieve history of workflow executions."""
    # In production this would query a database, but for now we'll return simulated data
    try:
        history = [
            {
                "id": f"niche-scout-{int(datetime.now().timestamp()) - 3600}",
                "workflow_type": "niche-scout",
                "parameters": {"query": "mobile gaming"},
                "status": "completed",
                "started_at": (datetime.now().replace(hour=datetime.now().hour - 1)).isoformat(),
                "completed_at": (datetime.now().replace(hour=datetime.now().hour - 1, minute=datetime.now().minute + 5)).isoformat(),
                "result_url": f"/workflow-result/niche-scout-{int(datetime.now().timestamp()) - 3600}?type=niche-scout",
                "user_id": "user-1"
            },
            {
                "id": f"blueprint-{int(datetime.now().timestamp()) - 7200}",
                "workflow_type": "seed-to-blueprint",
                "parameters": {"video_url": "https://youtube.com/watch?v=example123"},
                "status": "completed",
                "started_at": (datetime.now().replace(hour=datetime.now().hour - 2)).isoformat(),
                "completed_at": (datetime.now().replace(hour=datetime.now().hour - 2, minute=datetime.now().minute + 8)).isoformat(),
                "result_url": f"/workflow-result/blueprint-{int(datetime.now().timestamp()) - 7200}?type=seed-to-blueprint",
                "user_id": "user-1"
            },
            {
                "id": f"niche-scout-{int(datetime.now().timestamp()) - 86400}",
                "workflow_type": "niche-scout",
                "parameters": {"query": "cooking recipes"},
                "status": "completed",
                "started_at": (datetime.now().replace(day=datetime.now().day - 1)).isoformat(),
                "completed_at": (datetime.now().replace(day=datetime.now().day - 1, minute=datetime.now().minute + 6)).isoformat(),
                "result_url": f"/workflow-result/niche-scout-{int(datetime.now().timestamp()) - 86400}?type=niche-scout",
                "user_id": "user-1"
            }
        ]
        return history
    except Exception as e:
        logger.error("error_retrieving_workflow_history", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))
```

### 3. Add Scheduled Workflows Endpoints

Add endpoints for scheduled workflows:

```python
@app.get("/scheduled-workflows")
async def get_scheduled_workflows():
    """Retrieve scheduled workflows."""
    # In production this would query a database
    try:
        scheduled = [
            {
                "id": f"sched-{int(datetime.now().timestamp()) - 600}",
                "workflow_type": "niche-scout",
                "parameters": {"query": "gaming"},
                "frequency": "daily",
                "next_run": (datetime.now().replace(day=datetime.now().day + 1)).isoformat(),
                "status": "scheduled",
                "created_at": (datetime.now().replace(minute=datetime.now().minute - 10)).isoformat(),
                "updated_at": (datetime.now().replace(minute=datetime.now().minute - 10)).isoformat(),
                "user_id": "user-1"
            },
            {
                "id": f"sched-{int(datetime.now().timestamp()) - 1200}",
                "workflow_type": "seed-to-blueprint",
                "parameters": {"niche": "fitness"},
                "frequency": "weekly",
                "next_run": (datetime.now().replace(day=datetime.now().day + 7)).isoformat(),
                "status": "scheduled",
                "created_at": (datetime.now().replace(minute=datetime.now().minute - 20)).isoformat(),
                "updated_at": (datetime.now().replace(minute=datetime.now().minute - 20)).isoformat(),
                "user_id": "user-1"
            }
        ]
        return scheduled
    except Exception as e:
        logger.error("error_retrieving_scheduled_workflows", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/schedule-workflow")
async def schedule_workflow(
    workflow_type: str = Body(..., description="Type of workflow to schedule"),
    parameters: Dict[str, Any] = Body(..., description="Workflow parameters"),
    frequency: str = Body(..., description="Schedule frequency (daily, weekly, monthly, once)"),
    next_run: str = Body(..., description="Next scheduled run time")
):
    """Schedule a new workflow execution."""
    try:
        # In production this would store to a database
        schedule_id = f"sched-{int(datetime.now().timestamp())}"

        # Return the created schedule
        return {
            "id": schedule_id,
            "workflow_type": workflow_type,
            "parameters": parameters,
            "frequency": frequency,
            "next_run": next_run,
            "status": "scheduled",
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "user_id": "user-1"
        }
    except Exception as e:
        logger.error("error_scheduling_workflow", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))
```

### 4. Add Alternative Endpoint Paths for Better Resilience

To match the try-multiple-paths approach in the mission-control service, we should add alternative routes to the existing endpoints:

```python
# Alternative routes for Niche-Scout
@app.post("/youtube/niche-scout")
async def run_niche_scout_alt1(query: str = Query(None)):
    """Alternative path for Niche-Scout workflow."""
    return await run_niche_scout(query)

@app.post("/api/youtube/niche-scout")
async def run_niche_scout_alt2(query: str = Query(None)):
    """Alternative path for Niche-Scout workflow."""
    return await run_niche_scout(query)

# Alternative routes for Seed-to-Blueprint
@app.post("/youtube/blueprint")
async def run_seed_to_blueprint_alt1(
    video_url: str = Query(None),
    niche: str = Query(None)
):
    """Alternative path for Seed-to-Blueprint workflow."""
    return await run_seed_to_blueprint(video_url, niche)

@app.post("/api/youtube/blueprint")
async def run_seed_to_blueprint_alt2(
    video_url: str = Query(None),
    niche: str = Query(None)
):
    """Alternative path for Seed-to-Blueprint workflow."""
    return await run_seed_to_blueprint(video_url, niche)

# Alternative routes for workflow results
@app.get("/youtube/workflow-result/{result_id}")
async def get_workflow_result_alt1(result_id: str, type: str = Query(...)):
    """Alternative path for workflow results."""
    return await get_workflow_result(result_id, type)

@app.get("/api/youtube/workflow-result/{result_id}")
async def get_workflow_result_alt2(result_id: str, type: str = Query(...)):
    """Alternative path for workflow results."""
    return await get_workflow_result(result_id, type)

# Alternative routes for workflow history
@app.get("/youtube/workflow-history")
async def get_workflow_history_alt1():
    """Alternative path for workflow history."""
    return await get_workflow_history()

@app.get("/api/youtube/workflow-history")
async def get_workflow_history_alt2():
    """Alternative path for workflow history."""
    return await get_workflow_history()

# Alternative routes for scheduled workflows
@app.get("/youtube/scheduled-workflows")
async def get_scheduled_workflows_alt1():
    """Alternative path for scheduled workflows."""
    return await get_scheduled_workflows()

@app.get("/api/youtube/scheduled-workflows")
async def get_scheduled_workflows_alt2():
    """Alternative path for scheduled workflows."""
    return await get_scheduled_workflows()

# Alternative routes for scheduling workflows
@app.post("/youtube/schedule-workflow")
async def schedule_workflow_alt1(
    workflow_type: str = Body(...),
    parameters: Dict[str, Any] = Body(...),
    frequency: str = Body(...),
    next_run: str = Body(...)
):
    """Alternative path for scheduling workflows."""
    return await schedule_workflow(workflow_type, parameters, frequency, next_run)

@app.post("/api/youtube/schedule-workflow")
async def schedule_workflow_alt2(
    workflow_type: str = Body(...),
    parameters: Dict[str, Any] = Body(...),
    frequency: str = Body(...),
    next_run: str = Body(...)
):
    """Alternative path for scheduling workflows."""
    return await schedule_workflow(workflow_type, parameters, frequency, next_run)
```

## Deployment Steps

1. Create a new implementation file with the missing endpoints: `workflow_endpoints.py`
2. Update `app/main.py` to import and incorporate the new endpoints
3. Build an updated Docker image for the social-intel service
4. Deploy the updated container
5. Test the endpoints:
   - Test result retrieval: `curl http://localhost:9000/workflow-result/mock-id-123?type=niche-scout`
   - Test workflow history: `curl http://localhost:9000/workflow-history`
   - Test scheduled workflows: `curl http://localhost:9000/scheduled-workflows`

## Testing Plan

1. **Endpoint Testing**:
   - Test each new endpoint individually with curl to verify it returns the expected response
   - Test alternative paths to ensure they all work correctly

2. **Integration Testing**:
   - Test the full workflow from the Mission Control UI:
     1. Run Niche-Scout workflow
     2. Verify the result is properly displayed
     3. Run Seed-to-Blueprint workflow
     4. Verify the result is properly displayed
     5. Check the workflow history page
     6. Schedule a new workflow and verify it appears in scheduled workflows

3. **Error Handling Testing**:
   - Test with invalid IDs to ensure proper error handling
   - Test with invalid parameters to ensure validation works correctly

## Future Improvements

1. **Data Persistence**: Implement proper database storage for workflow results and history
2. **Authentication**: Add authentication to secure the API endpoints
3. **Rate Limiting**: Implement rate limiting to prevent abuse
4. **Monitoring**: Add detailed metrics collection for endpoint performance
5. **Documentation**: Generate OpenAPI documentation for all endpoints

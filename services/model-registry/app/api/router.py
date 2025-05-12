"""
API router for the Model Registry service.
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
from datetime import datetime, timedelta
import structlog

from app.core.db import get_db
from app.models.models import (
    ModelCreate, ModelRead, ModelUpdate, 
    ModelCapabilityCreate, ModelCapabilityRead,
    ModelParameterCreate, ModelParameterRead,
    ModelUsageCreate, ModelPerformanceCreate
)
from app.api.crud import (
    get_models, get_model, create_model, update_model, delete_model,
    get_model_capabilities, add_model_capability, delete_model_capability,
    get_model_parameters, add_model_parameter, update_model_parameter,
    record_model_usage, record_model_performance,
    get_model_usage_stats, get_model_performance_metrics
)

# Configure logging
logger = structlog.get_logger(__name__)

# Create API router
api_router = APIRouter()

#########################
# Model Management Routes
#########################

@api_router.get("/models", response_model=List[ModelRead])
async def list_models(
    provider: Optional[str] = None,
    model_type: Optional[str] = None,
    capability: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    """
    List all models in the registry.
    Optional filters by provider, model_type, and capability.
    """
    return await get_models(db, provider, model_type, capability)

@api_router.get("/models/{model_id}", response_model=ModelRead)
async def get_model_by_id(model_id: int, db: AsyncSession = Depends(get_db)):
    """Get a model by ID."""
    model = await get_model(db, model_id)
    if not model:
        raise HTTPException(status_code=404, detail="Model not found")
    return model

@api_router.post("/models", response_model=ModelRead)
async def create_new_model(model: ModelCreate, db: AsyncSession = Depends(get_db)):
    """Create a new model."""
    try:
        return await create_model(db, model)
    except Exception as e:
        logger.error("Error creating model", error=str(e))
        raise HTTPException(status_code=400, detail=str(e))

@api_router.put("/models/{model_id}", response_model=ModelRead)
async def update_existing_model(
    model_id: int, 
    model: ModelUpdate, 
    db: AsyncSession = Depends(get_db)
):
    """Update an existing model."""
    db_model = await get_model(db, model_id)
    if not db_model:
        raise HTTPException(status_code=404, detail="Model not found")
    
    try:
        return await update_model(db, model_id, model)
    except Exception as e:
        logger.error("Error updating model", error=str(e))
        raise HTTPException(status_code=400, detail=str(e))

@api_router.delete("/models/{model_id}")
async def delete_existing_model(model_id: int, db: AsyncSession = Depends(get_db)):
    """Delete a model."""
    db_model = await get_model(db, model_id)
    if not db_model:
        raise HTTPException(status_code=404, detail="Model not found")
    
    try:
        await delete_model(db, model_id)
        return {"message": "Model deleted successfully"}
    except Exception as e:
        logger.error("Error deleting model", error=str(e))
        raise HTTPException(status_code=400, detail=str(e))

#########################
# Capability Routes
#########################

@api_router.get("/models/{model_id}/capabilities", response_model=List[ModelCapabilityRead])
async def list_model_capabilities(model_id: int, db: AsyncSession = Depends(get_db)):
    """List all capabilities for a model."""
    db_model = await get_model(db, model_id)
    if not db_model:
        raise HTTPException(status_code=404, detail="Model not found")
    
    return await get_model_capabilities(db, model_id)

@api_router.post("/models/{model_id}/capabilities", response_model=ModelCapabilityRead)
async def add_capability_to_model(
    model_id: int, 
    capability: ModelCapabilityCreate, 
    db: AsyncSession = Depends(get_db)
):
    """Add a capability to a model."""
    db_model = await get_model(db, model_id)
    if not db_model:
        raise HTTPException(status_code=404, detail="Model not found")
    
    try:
        return await add_model_capability(db, model_id, capability)
    except Exception as e:
        logger.error("Error adding capability", error=str(e))
        raise HTTPException(status_code=400, detail=str(e))

@api_router.delete("/models/{model_id}/capabilities/{capability}")
async def delete_capability_from_model(
    model_id: int, 
    capability: str, 
    db: AsyncSession = Depends(get_db)
):
    """Delete a capability from a model."""
    db_model = await get_model(db, model_id)
    if not db_model:
        raise HTTPException(status_code=404, detail="Model not found")
    
    try:
        await delete_model_capability(db, model_id, capability)
        return {"message": "Capability deleted successfully"}
    except Exception as e:
        logger.error("Error deleting capability", error=str(e))
        raise HTTPException(status_code=400, detail=str(e))

#########################
# Parameter Routes
#########################

@api_router.get("/models/{model_id}/parameters", response_model=List[ModelParameterRead])
async def list_model_parameters(model_id: int, db: AsyncSession = Depends(get_db)):
    """List all parameters for a model."""
    db_model = await get_model(db, model_id)
    if not db_model:
        raise HTTPException(status_code=404, detail="Model not found")
    
    return await get_model_parameters(db, model_id)

@api_router.post("/models/{model_id}/parameters", response_model=ModelParameterRead)
async def add_parameter_to_model(
    model_id: int, 
    parameter: ModelParameterCreate, 
    db: AsyncSession = Depends(get_db)
):
    """Add a parameter to a model."""
    db_model = await get_model(db, model_id)
    if not db_model:
        raise HTTPException(status_code=404, detail="Model not found")
    
    try:
        return await add_model_parameter(db, model_id, parameter)
    except Exception as e:
        logger.error("Error adding parameter", error=str(e))
        raise HTTPException(status_code=400, detail=str(e))

@api_router.put("/models/{model_id}/parameters/{parameter_name}", response_model=ModelParameterRead)
async def update_model_parameter_value(
    model_id: int, 
    parameter_name: str, 
    parameter: ModelParameterCreate, 
    db: AsyncSession = Depends(get_db)
):
    """Update a parameter for a model."""
    db_model = await get_model(db, model_id)
    if not db_model:
        raise HTTPException(status_code=404, detail="Model not found")
    
    try:
        return await update_model_parameter(db, model_id, parameter_name, parameter)
    except Exception as e:
        logger.error("Error updating parameter", error=str(e))
        raise HTTPException(status_code=400, detail=str(e))

#########################
# Usage Tracking Routes
#########################

@api_router.post("/models/{model_id}/usage")
async def record_usage(
    model_id: int, 
    usage: ModelUsageCreate, 
    db: AsyncSession = Depends(get_db)
):
    """Record usage statistics for a model."""
    db_model = await get_model(db, model_id)
    if not db_model:
        raise HTTPException(status_code=404, detail="Model not found")
    
    try:
        await record_model_usage(db, model_id, usage)
        return {"message": "Usage recorded successfully"}
    except Exception as e:
        logger.error("Error recording usage", error=str(e))
        raise HTTPException(status_code=400, detail=str(e))

@api_router.post("/models/{model_id}/performance")
async def record_performance(
    model_id: int, 
    performance: ModelPerformanceCreate, 
    db: AsyncSession = Depends(get_db)
):
    """Record performance metrics for a model."""
    db_model = await get_model(db, model_id)
    if not db_model:
        raise HTTPException(status_code=404, detail="Model not found")
    
    try:
        await record_model_performance(db, model_id, performance)
        return {"message": "Performance recorded successfully"}
    except Exception as e:
        logger.error("Error recording performance", error=str(e))
        raise HTTPException(status_code=400, detail=str(e))

#########################
# Statistics Routes
#########################

@api_router.get("/models/{model_id}/usage/stats")
async def get_model_usage_statistics(
    model_id: int, 
    start_date: Optional[datetime] = Query(None),
    end_date: Optional[datetime] = Query(None),
    db: AsyncSession = Depends(get_db)
):
    """Get usage statistics for a model."""
    db_model = await get_model(db, model_id)
    if not db_model:
        raise HTTPException(status_code=404, detail="Model not found")
    
    # Default to last 7 days if not specified
    if not start_date:
        start_date = datetime.now() - timedelta(days=7)
    if not end_date:
        end_date = datetime.now()
    
    try:
        return await get_model_usage_stats(db, model_id, start_date, end_date)
    except Exception as e:
        logger.error("Error getting usage stats", error=str(e))
        raise HTTPException(status_code=400, detail=str(e))

@api_router.get("/models/{model_id}/performance/metrics")
async def get_model_performance_statistics(
    model_id: int, 
    metric_name: Optional[str] = None,
    start_date: Optional[datetime] = Query(None),
    end_date: Optional[datetime] = Query(None),
    db: AsyncSession = Depends(get_db)
):
    """Get performance metrics for a model."""
    db_model = await get_model(db, model_id)
    if not db_model:
        raise HTTPException(status_code=404, detail="Model not found")
    
    # Default to last 7 days if not specified
    if not start_date:
        start_date = datetime.now() - timedelta(days=7)
    if not end_date:
        end_date = datetime.now()
    
    try:
        return await get_model_performance_metrics(db, model_id, metric_name, start_date, end_date)
    except Exception as e:
        logger.error("Error getting performance metrics", error=str(e))
        raise HTTPException(status_code=400, detail=str(e))

#########################
# Model Selection Routes
#########################

@api_router.get("/model/available")
async def list_available_models(
    capability: Optional[str] = None,
    min_score: Optional[float] = 0.5,
    provider: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    """
    List all available models that match the specified criteria.
    This endpoint is used by the model router for model selection.
    """
    models = await get_models(db, provider=provider, capability=capability)
    
    # Filter by capability score if specified
    if capability and min_score > 0:
        filtered_models = []
        for model in models:
            for cap in model.capabilities:
                if cap.capability == capability and cap.capability_score >= min_score:
                    filtered_models.append(model)
                    break
        return filtered_models
    
    return models
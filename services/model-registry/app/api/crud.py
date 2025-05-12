"""
CRUD operations for the Model Registry service.
"""
import json
from typing import List, Optional, Dict, Any
from datetime import datetime
from sqlalchemy import select, update, delete, and_, or_, func
from sqlalchemy.ext.asyncio import AsyncSession
import structlog

from app.models.models import (
    Model, ModelEndpoint, ModelCapability, ModelParameter,
    ModelPerformance, ModelUsage,
    ModelCreate, ModelUpdate, ModelCapabilityCreate, ModelParameterCreate,
    ModelUsageCreate, ModelPerformanceCreate
)

# Configure logging
logger = structlog.get_logger(__name__)

#########################
# Model CRUD Operations
#########################

async def get_models(
    db: AsyncSession, 
    provider: Optional[str] = None, 
    model_type: Optional[str] = None,
    capability: Optional[str] = None
) -> List[Model]:
    """
    Get all models from the database, with optional filtering.
    """
    query = select(Model)
    
    # Apply filters if provided
    if provider:
        query = query.filter(Model.provider == provider)
    if model_type:
        query = query.filter(Model.model_type == model_type)
    if capability:
        # Join with capabilities table and filter
        query = query.join(ModelCapability).filter(ModelCapability.capability == capability)
    
    # Execute query
    result = await db.execute(query)
    models = result.scalars().all()
    
    # Load relationships
    for model in models:
        await db.refresh(model, ["capabilities", "endpoints", "parameters"])
    
    return models

async def get_model(db: AsyncSession, model_id: int) -> Optional[Model]:
    """
    Get a model by ID.
    """
    query = select(Model).filter(Model.id == model_id)
    result = await db.execute(query)
    model = result.scalars().first()
    
    if model:
        # Load relationships
        await db.refresh(model, ["capabilities", "endpoints", "parameters"])
    
    return model

async def create_model(db: AsyncSession, model_data: ModelCreate) -> Model:
    """
    Create a new model.
    """
    # Check if model with same name already exists
    query = select(Model).filter(Model.name == model_data.name)
    result = await db.execute(query)
    existing_model = result.scalars().first()
    
    if existing_model:
        raise ValueError(f"Model with name {model_data.name} already exists")
    
    # Create model
    db_model = Model(
        name=model_data.name,
        display_name=model_data.display_name,
        provider=model_data.provider,
        model_type=model_data.model_type,
        version=model_data.version,
        description=model_data.description
    )
    db.add(db_model)
    await db.commit()
    await db.refresh(db_model)
    
    # Add capabilities
    for capability in model_data.capabilities:
        db_capability = ModelCapability(
            model_id=db_model.id,
            capability=capability.capability,
            capability_score=capability.capability_score
        )
        db.add(db_capability)
    
    # Add endpoints
    for endpoint in model_data.endpoints:
        db_endpoint = ModelEndpoint(
            model_id=db_model.id,
            endpoint_type=endpoint.endpoint_type,
            endpoint_url=endpoint.endpoint_url,
            auth_type=endpoint.auth_type,
            headers=endpoint.headers
        )
        db.add(db_endpoint)
    
    # Add parameters
    for parameter in model_data.parameters:
        db_parameter = ModelParameter(
            model_id=db_model.id,
            parameter_name=parameter.parameter_name,
            default_value=parameter.default_value,
            min_value=parameter.min_value,
            max_value=parameter.max_value,
            description=parameter.description
        )
        db.add(db_parameter)
    
    # Commit changes
    await db.commit()
    
    # Refresh model with relationships
    await db.refresh(db_model, ["capabilities", "endpoints", "parameters"])
    
    return db_model

async def update_model(db: AsyncSession, model_id: int, model_data: ModelUpdate) -> Model:
    """
    Update an existing model.
    """
    # Get model
    query = select(Model).filter(Model.id == model_id)
    result = await db.execute(query)
    db_model = result.scalars().first()
    
    if not db_model:
        raise ValueError(f"Model with ID {model_id} not found")
    
    # Update model fields
    update_data = model_data.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_model, key, value)
    
    # Update timestamp
    db_model.updated_at = datetime.now()
    
    # Commit changes
    await db.commit()
    
    # Refresh model with relationships
    await db.refresh(db_model, ["capabilities", "endpoints", "parameters"])
    
    return db_model

async def delete_model(db: AsyncSession, model_id: int) -> None:
    """
    Delete a model.
    """
    # Get model
    query = select(Model).filter(Model.id == model_id)
    result = await db.execute(query)
    db_model = result.scalars().first()
    
    if not db_model:
        raise ValueError(f"Model with ID {model_id} not found")
    
    # Delete model
    await db.delete(db_model)
    
    # Commit changes
    await db.commit()

#########################
# Capability CRUD Operations
#########################

async def get_model_capabilities(db: AsyncSession, model_id: int) -> List[ModelCapability]:
    """
    Get all capabilities for a model.
    """
    query = select(ModelCapability).filter(ModelCapability.model_id == model_id)
    result = await db.execute(query)
    return result.scalars().all()

async def add_model_capability(
    db: AsyncSession, 
    model_id: int, 
    capability: ModelCapabilityCreate
) -> ModelCapability:
    """
    Add a capability to a model.
    """
    # Check if capability already exists
    query = select(ModelCapability).filter(
        and_(
            ModelCapability.model_id == model_id,
            ModelCapability.capability == capability.capability
        )
    )
    result = await db.execute(query)
    existing_capability = result.scalars().first()
    
    if existing_capability:
        # Update existing capability
        existing_capability.capability_score = capability.capability_score
        await db.commit()
        await db.refresh(existing_capability)
        return existing_capability
    
    # Create new capability
    db_capability = ModelCapability(
        model_id=model_id,
        capability=capability.capability,
        capability_score=capability.capability_score
    )
    db.add(db_capability)
    await db.commit()
    await db.refresh(db_capability)
    
    return db_capability

async def delete_model_capability(db: AsyncSession, model_id: int, capability: str) -> None:
    """
    Delete a capability from a model.
    """
    # Check if capability exists
    query = select(ModelCapability).filter(
        and_(
            ModelCapability.model_id == model_id,
            ModelCapability.capability == capability
        )
    )
    result = await db.execute(query)
    db_capability = result.scalars().first()
    
    if not db_capability:
        raise ValueError(f"Capability {capability} not found for model {model_id}")
    
    # Delete capability
    await db.delete(db_capability)
    
    # Commit changes
    await db.commit()

#########################
# Parameter CRUD Operations
#########################

async def get_model_parameters(db: AsyncSession, model_id: int) -> List[ModelParameter]:
    """
    Get all parameters for a model.
    """
    query = select(ModelParameter).filter(ModelParameter.model_id == model_id)
    result = await db.execute(query)
    return result.scalars().all()

async def add_model_parameter(
    db: AsyncSession, 
    model_id: int, 
    parameter: ModelParameterCreate
) -> ModelParameter:
    """
    Add a parameter to a model.
    """
    # Check if parameter already exists
    query = select(ModelParameter).filter(
        and_(
            ModelParameter.model_id == model_id,
            ModelParameter.parameter_name == parameter.parameter_name
        )
    )
    result = await db.execute(query)
    existing_parameter = result.scalars().first()
    
    if existing_parameter:
        # Update existing parameter
        existing_parameter.default_value = parameter.default_value
        existing_parameter.min_value = parameter.min_value
        existing_parameter.max_value = parameter.max_value
        existing_parameter.description = parameter.description
        await db.commit()
        await db.refresh(existing_parameter)
        return existing_parameter
    
    # Convert JSON fields to strings if they are Python dictionaries
    default_value = parameter.default_value
    min_value = parameter.min_value
    max_value = parameter.max_value
    
    if isinstance(default_value, dict):
        default_value = json.dumps(default_value)
    if isinstance(min_value, dict):
        min_value = json.dumps(min_value)
    if isinstance(max_value, dict):
        max_value = json.dumps(max_value)
    
    # Create new parameter
    db_parameter = ModelParameter(
        model_id=model_id,
        parameter_name=parameter.parameter_name,
        default_value=default_value,
        min_value=min_value,
        max_value=max_value,
        description=parameter.description
    )
    db.add(db_parameter)
    await db.commit()
    await db.refresh(db_parameter)
    
    return db_parameter

async def update_model_parameter(
    db: AsyncSession, 
    model_id: int, 
    parameter_name: str, 
    parameter: ModelParameterCreate
) -> ModelParameter:
    """
    Update a parameter for a model.
    """
    # Check if parameter exists
    query = select(ModelParameter).filter(
        and_(
            ModelParameter.model_id == model_id,
            ModelParameter.parameter_name == parameter_name
        )
    )
    result = await db.execute(query)
    db_parameter = result.scalars().first()
    
    if not db_parameter:
        # Parameter doesn't exist, create it
        return await add_model_parameter(db, model_id, parameter)
    
    # Update parameter fields
    db_parameter.parameter_name = parameter.parameter_name
    db_parameter.default_value = parameter.default_value
    db_parameter.min_value = parameter.min_value
    db_parameter.max_value = parameter.max_value
    db_parameter.description = parameter.description
    
    # Commit changes
    await db.commit()
    await db.refresh(db_parameter)
    
    return db_parameter

#########################
# Usage Tracking Operations
#########################

async def record_model_usage(db: AsyncSession, model_id: int, usage: ModelUsageCreate) -> None:
    """
    Record usage statistics for a model.
    """
    # Create usage record
    db_usage = ModelUsage(
        model_id=model_id,
        token_count=usage.token_count,
        request_count=usage.request_count,
        average_latency=usage.average_latency,
        error_count=usage.error_count,
        cost=usage.cost
    )
    db.add(db_usage)
    
    # Commit changes
    await db.commit()

async def record_model_performance(
    db: AsyncSession, 
    model_id: int, 
    performance: ModelPerformanceCreate
) -> None:
    """
    Record performance metrics for a model.
    """
    # Create performance record
    db_performance = ModelPerformance(
        model_id=model_id,
        metric_name=performance.metric_name,
        metric_value=performance.metric_value,
        task_category=performance.task_category,
        sample_size=performance.sample_size
    )
    db.add(db_performance)
    
    # Commit changes
    await db.commit()

#########################
# Statistics Operations
#########################

async def get_model_usage_stats(
    db: AsyncSession, 
    model_id: int, 
    start_date: datetime, 
    end_date: datetime
) -> Dict[str, Any]:
    """
    Get usage statistics for a model.
    """
    # Query for total requests
    total_requests_query = select(func.sum(ModelUsage.request_count)).filter(
        and_(
            ModelUsage.model_id == model_id,
            ModelUsage.timestamp >= start_date,
            ModelUsage.timestamp <= end_date
        )
    )
    total_requests_result = await db.execute(total_requests_query)
    total_requests = total_requests_result.scalar() or 0
    
    # Query for total tokens
    total_tokens_query = select(func.sum(ModelUsage.token_count)).filter(
        and_(
            ModelUsage.model_id == model_id,
            ModelUsage.timestamp >= start_date,
            ModelUsage.timestamp <= end_date
        )
    )
    total_tokens_result = await db.execute(total_tokens_query)
    total_tokens = total_tokens_result.scalar() or 0
    
    # Query for average latency
    avg_latency_query = select(func.avg(ModelUsage.average_latency)).filter(
        and_(
            ModelUsage.model_id == model_id,
            ModelUsage.timestamp >= start_date,
            ModelUsage.timestamp <= end_date,
            ModelUsage.average_latency.is_not(None)
        )
    )
    avg_latency_result = await db.execute(avg_latency_query)
    avg_latency = avg_latency_result.scalar() or 0
    
    # Query for error count
    error_count_query = select(func.sum(ModelUsage.error_count)).filter(
        and_(
            ModelUsage.model_id == model_id,
            ModelUsage.timestamp >= start_date,
            ModelUsage.timestamp <= end_date
        )
    )
    error_count_result = await db.execute(error_count_query)
    error_count = error_count_result.scalar() or 0
    
    # Calculate error rate
    error_rate = 0
    if total_requests > 0:
        error_rate = (error_count / total_requests) * 100
    
    # Query for total cost
    total_cost_query = select(func.sum(ModelUsage.cost)).filter(
        and_(
            ModelUsage.model_id == model_id,
            ModelUsage.timestamp >= start_date,
            ModelUsage.timestamp <= end_date,
            ModelUsage.cost.is_not(None)
        )
    )
    total_cost_result = await db.execute(total_cost_query)
    total_cost = total_cost_result.scalar() or 0
    
    # Get usage over time
    usage_over_time_query = select(
        func.date_trunc('day', ModelUsage.timestamp).label('date'),
        func.sum(ModelUsage.request_count).label('requests'),
        func.sum(ModelUsage.token_count).label('tokens'),
        func.avg(ModelUsage.average_latency).label('latency'),
        func.sum(ModelUsage.error_count).label('errors'),
        func.sum(ModelUsage.cost).label('cost')
    ).filter(
        and_(
            ModelUsage.model_id == model_id,
            ModelUsage.timestamp >= start_date,
            ModelUsage.timestamp <= end_date
        )
    ).group_by(func.date_trunc('day', ModelUsage.timestamp))
    
    usage_over_time_result = await db.execute(usage_over_time_query)
    usage_over_time = []
    
    for row in usage_over_time_result:
        usage_over_time.append({
            'date': row.date.strftime('%Y-%m-%d'),
            'requests': row.requests,
            'tokens': row.tokens,
            'latency': row.latency,
            'errors': row.errors,
            'cost': row.cost
        })
    
    # Return statistics
    return {
        'total_requests': total_requests,
        'total_tokens': total_tokens,
        'avg_response_time': avg_latency,
        'error_count': error_count,
        'error_rate': error_rate,
        'total_cost': total_cost,
        'usage_over_time': usage_over_time
    }

async def get_model_performance_metrics(
    db: AsyncSession, 
    model_id: int, 
    metric_name: Optional[str], 
    start_date: datetime, 
    end_date: datetime
) -> Dict[str, Any]:
    """
    Get performance metrics for a model.
    """
    # Base query
    query = select(ModelPerformance).filter(
        and_(
            ModelPerformance.model_id == model_id,
            ModelPerformance.timestamp >= start_date,
            ModelPerformance.timestamp <= end_date
        )
    )
    
    # Apply metric filter if specified
    if metric_name:
        query = query.filter(ModelPerformance.metric_name == metric_name)
    
    # Execute query
    result = await db.execute(query)
    metrics = result.scalars().all()
    
    # Group metrics by name
    metrics_by_name = {}
    for metric in metrics:
        if metric.metric_name not in metrics_by_name:
            metrics_by_name[metric.metric_name] = []
        
        metrics_by_name[metric.metric_name].append({
            'timestamp': metric.timestamp.isoformat(),
            'value': metric.metric_value,
            'task_category': metric.task_category,
            'sample_size': metric.sample_size
        })
    
    # Calculate statistics for each metric
    metrics_stats = {}
    for name, values in metrics_by_name.items():
        metric_values = [v['value'] for v in values]
        metrics_stats[name] = {
            'min': min(metric_values) if metric_values else 0,
            'max': max(metric_values) if metric_values else 0,
            'avg': sum(metric_values) / len(metric_values) if metric_values else 0,
            'count': len(metric_values),
            'values': values
        }
    
    # Return metrics
    return {
        'metrics': metrics_stats
    }
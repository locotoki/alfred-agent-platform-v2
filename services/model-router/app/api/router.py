from fastapi import APIRouter, Depends, HTTPException, Request, BackgroundTasks
from typing import List, Dict, Any, Optional
import logging
import uuid
from datetime import datetime

from app.models.models import (
    RoutingRequest,
    RoutingResponse,
    RoutingMetrics,
    ContentItem,
    ContentType,
    TaskType
)
from app.services.router_engine import RouterEngine
from app.services.request_analyzer import RequestAnalyzer
from app.services.model_dispatcher import ModelDispatcher

logger = logging.getLogger(__name__)

router = APIRouter(tags=["models"])

# Helper function to get router engine from app state
async def get_router_engine(request: Request) -> RouterEngine:
    return request.app.state.router_engine

# Helper function to get or create request analyzer
async def get_request_analyzer(request: Request) -> RequestAnalyzer:
    if not hasattr(request.app.state, "request_analyzer"):
        request.app.state.request_analyzer = RequestAnalyzer()
    return request.app.state.request_analyzer

# Helper function to get or create model dispatcher
async def get_model_dispatcher(request: Request) -> ModelDispatcher:
    if not hasattr(request.app.state, "model_dispatcher"):
        request.app.state.model_dispatcher = ModelDispatcher()
        await request.app.state.model_dispatcher.initialize()
    return request.app.state.model_dispatcher


@router.post("/route", response_model=RoutingResponse, summary="Route a request to the most appropriate model")
async def route_request(
    request: RoutingRequest,
    background_tasks: BackgroundTasks,
    router_engine: RouterEngine = Depends(get_router_engine),
    request_analyzer: RequestAnalyzer = Depends(get_request_analyzer)
):
    """
    Route a request to the most appropriate model based on content, task type, and other factors.
    
    - Analyzes the request to determine content characteristics
    - Applies selection rules to choose the best model
    - Returns routing information including endpoint URL and authentication requirements
    """
    logger.info(f"Processing routing request {request.id}")
    
    # Analyze request for additional insights
    analysis = request_analyzer.analyze_request(request)
    logger.info(f"Request analysis: {analysis}")
    
    # Route the request to the appropriate model
    routing_response = await router_engine.route_request(request)
    
    return routing_response


@router.post("/process", summary="Process a request with the most appropriate model")
async def process_request(
    request_payload: Dict[str, Any],
    background_tasks: BackgroundTasks,
    router_engine: RouterEngine = Depends(get_router_engine),
    request_analyzer: RequestAnalyzer = Depends(get_request_analyzer),
    model_dispatcher: ModelDispatcher = Depends(get_model_dispatcher)
):
    """
    End-to-end processing of a request:
    
    1. Converts raw request into structured format
    2. Routes to appropriate model
    3. Dispatches to selected model
    4. Returns model response
    
    This is a convenience endpoint that combines routing and dispatching.
    """
    # Generate request ID if not provided
    request_id = request_payload.get("id", str(uuid.uuid4()))
    
    # Extract basic fields
    task_type_str = request_payload.get("task_type", "chat")
    try:
        task_type = TaskType(task_type_str)
    except ValueError:
        task_type = TaskType.CHAT
        
    # Handle raw text content or structured content
    if "content" in request_payload and isinstance(request_payload["content"], str):
        # Process raw text into structured content
        content_items = request_analyzer.process_raw_text(request_payload["content"])
    elif "content" in request_payload and isinstance(request_payload["content"], list):
        # Use provided structured content
        content_items = [
            ContentItem(
                type=item.get("type", ContentType.TEXT),
                content=item.get("content", ""),
                metadata=item.get("metadata", {})
            )
            for item in request_payload["content"]
        ]
    else:
        # Default to empty content
        content_items = []
        
    # Create routing request
    routing_request = RoutingRequest(
        id=request_id,
        timestamp=datetime.utcnow(),
        task_type=task_type,
        content=content_items,
        model_preference=request_payload.get("model"),
        force_model=request_payload.get("force_model"),
        parameters=request_payload.get("parameters", {})
    )
    
    # Extract context if provided
    if "context" in request_payload:
        for key, value in request_payload["context"].items():
            if hasattr(routing_request.context, key):
                setattr(routing_request.context, key, value)
                
    # Route the request
    routing_response = await router_engine.route_request(routing_request)
    
    # Dispatch the request to the selected model
    headers = {}
    if "headers" in request_payload:
        headers = request_payload["headers"]
        
    # Prepare payload for model
    model_payload = {
        "content": request_payload.get("content", ""),
        "task_type": task_type_str,
        "parameters": request_payload.get("parameters", {})
    }
    
    # Add any additional fields from original request
    for key, value in request_payload.items():
        if key not in ["id", "content", "task_type", "parameters", "model", "force_model", "context", "headers"]:
            model_payload[key] = value
            
    # Dispatch to model
    response = await model_dispatcher.dispatch_request(
        routing_response,
        model_payload,
        headers
    )
    
    # Add routing information to response
    response["_routing"] = {
        "model": routing_response.selected_model,
        "routing_reason": routing_response.routing_reason,
        "confidence": routing_response.selection_confidence,
        "request_id": routing_response.request_id
    }
    
    return response


@router.post("/generate/{model_id}", summary="Generate response using a specific model")
async def generate_with_model(
    model_id: str,
    request_payload: Dict[str, Any],
    background_tasks: BackgroundTasks,
    router_engine: RouterEngine = Depends(get_router_engine),
    model_dispatcher: ModelDispatcher = Depends(get_model_dispatcher)
):
    """
    Generate a response using a specific model.
    
    This endpoint allows direct access to a particular model,
    bypassing the automatic model selection process.
    """
    # Generate request ID if not provided
    request_id = request_payload.get("id", str(uuid.uuid4()))
    
    # Create a direct routing response
    routing_response = RoutingResponse(
        request_id=request_id,
        selected_model=model_id,
        fallback_models=[],
        routing_reason="direct model selection",
        selection_confidence=1.0,
        endpoint_url=f"/api/v1/models/{model_id}/generate",
        auth_required=True,
        additional_parameters={}
    )
    
    # Get fallback models if available
    try:
        # Try to get fallbacks from settings
        from app.core.config import settings
        fallbacks = settings.FALLBACK_MODELS.get(model_id, [])
        routing_response.fallback_models = fallbacks
    except Exception:
        pass
    
    # Dispatch to model
    headers = {}
    if "headers" in request_payload:
        headers = request_payload.pop("headers")
        
    response = await model_dispatcher.dispatch_request(
        routing_response,
        request_payload,
        headers
    )
    
    return response


@router.get("/models", summary="List available models")
async def list_models(
    router_engine: RouterEngine = Depends(get_router_engine)
):
    """
    List all available models in the system.
    
    This endpoint returns information about all models
    including their capabilities and configuration.
    """
    try:
        models = await router_engine.registry_client.get_models()
        return models
    except Exception as e:
        logger.error(f"Failed to list models: {e}")
        raise HTTPException(status_code=503, detail=f"Failed to retrieve models: {e}")


@router.get("/models/{model_id}", summary="Get model details")
async def get_model(
    model_id: str,
    router_engine: RouterEngine = Depends(get_router_engine)
):
    """
    Get detailed information about a specific model.
    
    This endpoint returns configuration details, capabilities,
    and usage statistics for the requested model.
    """
    try:
        model = await router_engine.registry_client.get_model(model_id)
        capabilities = await router_engine.registry_client.get_model_capabilities(model_id)
        
        return {
            "model": model,
            "capabilities": capabilities
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get model {model_id}: {e}")
        raise HTTPException(status_code=503, detail=f"Failed to retrieve model: {e}")


@router.get("/models/task/{task_type}", summary="Get models by task type")
async def get_models_by_task(
    task_type: str,
    router_engine: RouterEngine = Depends(get_router_engine)
):
    """
    Get models that support a specific task type.
    
    This endpoint returns all models that can handle
    the specified task type (e.g., chat, completion, etc.).
    """
    try:
        models = await router_engine.registry_client.get_models_by_task(task_type)
        return models
    except Exception as e:
        logger.error(f"Failed to get models for task {task_type}: {e}")
        raise HTTPException(status_code=503, detail=f"Failed to retrieve models: {e}")


@router.get("/models/content/{content_type}", summary="Get models by content type")
async def get_models_by_content(
    content_type: str,
    router_engine: RouterEngine = Depends(get_router_engine)
):
    """
    Get models that support a specific content type.
    
    This endpoint returns all models that can handle
    the specified content type (e.g., text, image, etc.).
    """
    try:
        models = await router_engine.registry_client.get_models_by_content_type(content_type)
        return models
    except Exception as e:
        logger.error(f"Failed to get models for content type {content_type}: {e}")
        raise HTTPException(status_code=503, detail=f"Failed to retrieve models: {e}")


@router.post("/metrics", summary="Log model usage metrics")
async def log_metrics(
    metrics: RoutingMetrics,
    router_engine: RouterEngine = Depends(get_router_engine)
):
    """
    Log metrics for model usage.
    
    This endpoint allows clients to report performance metrics
    for model usage, which helps with monitoring and optimization.
    """
    try:
        await router_engine.log_routing_metrics(metrics)
        return {"success": True}
    except Exception as e:
        logger.error(f"Failed to log metrics: {e}")
        return {"success": False, "error": str(e)}
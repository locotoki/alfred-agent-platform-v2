import logging
import aiohttp
import json
import time
import asyncio
import os
from typing import Dict, Any, Optional, List
from fastapi import HTTPException

from app.core.config import settings
from app.models.models import RoutingResponse, RoutingMetrics

logger = logging.getLogger(__name__)

class ModelDispatcher:
    """Service for dispatching requests to selected models"""

    def __init__(self):
        """Initialize the model dispatcher"""
        self.session = None
        self.endpoints_cache = {}
        self.locks = {}  # Locks for concurrency control per model

        # Configure model endpoints
        self.ollama_url = os.getenv("OLLAMA_URL", settings.OLLAMA_URL)
        self.openai_api_key = os.getenv("OPENAI_API_KEY", "")
        self.anthropic_api_key = os.getenv("ANTHROPIC_API_KEY", "")

    async def initialize(self):
        """Initialize the dispatcher"""
        if self.session is None:
            self.session = aiohttp.ClientSession()
            logger.info(f"Model dispatcher initialized (Ollama URL: {self.ollama_url})")

    async def close(self):
        """Close the HTTP session"""
        if self.session:
            await self.session.close()
            self.session = None

    def _get_model_lock(self, model_id: str) -> asyncio.Lock:
        """Get or create a lock for a model"""
        if model_id not in self.locks:
            self.locks[model_id] = asyncio.Lock()
        return self.locks[model_id]

    def _get_provider_from_model_id(self, model_id: str) -> str:
        """
        Determine the provider from the model ID.

        This is a simple heuristic that can be improved with better
        model registry integration.
        """
        model_id = model_id.lower()

        # Check for common provider prefixes
        if model_id.startswith(("llama", "codellama", "wizard", "mistral", "phi", "tinyllama", "llava")):
            return "ollama"
        elif model_id.startswith(("gpt", "text-embedding", "dall-e")):
            return "openai"
        elif model_id.startswith(("claude")):
            return "anthropic"

        # Default to ollama for unknown models
        return "ollama"
            
    async def dispatch_request(
        self,
        routing_response: RoutingResponse,
        request_payload: Dict[str, Any],
        headers: Optional[Dict[str, str]] = None
    ) -> Dict[str, Any]:
        """Dispatch a request to the selected model"""
        model_id = routing_response.selected_model
        provider = self._get_provider_from_model_id(model_id)

        # Initialize metrics
        start_time = time.time()
        metrics = RoutingMetrics(
            request_id=routing_response.request_id,
            model_id=model_id,
            task_type=request_payload.get("task_type", "chat"),
            content_types=[],
            content_token_count=0,
            success=False
        )

        # Try to extract content token count from the request
        if "content" in request_payload:
            if isinstance(request_payload["content"], str):
                metrics.content_token_count = len(request_payload["content"]) // 4  # Rough estimation
            elif isinstance(request_payload["content"], list):
                # For message-style content
                text_content = ""
                for item in request_payload["content"]:
                    if isinstance(item, dict) and "content" in item and isinstance(item["content"], str):
                        text_content += item["content"]
                    elif isinstance(item, str):
                        text_content += item
                metrics.content_token_count = len(text_content) // 4

        logger.info(f"Dispatching request to {provider} model: {model_id}")

        try:
            # Get the lock for this model
            model_lock = self._get_model_lock(model_id)

            # Use semaphore to control concurrent requests to the same model
            async with model_lock:
                # Dispatch based on provider
                if provider == "ollama":
                    response_data = await self._dispatch_to_ollama(model_id, request_payload, metrics)
                elif provider == "openai":
                    # For non-implemented providers, return placeholders
                    if not self.openai_api_key:
                        raise HTTPException(
                            status_code=401,
                            detail="OpenAI API key not configured"
                        )
                    response_data = {"error": "OpenAI integration not fully implemented yet"}
                elif provider == "anthropic":
                    if not self.anthropic_api_key:
                        raise HTTPException(
                            status_code=401,
                            detail="Anthropic API key not configured"
                        )
                    response_data = {"error": "Anthropic integration not fully implemented yet"}
                else:
                    # Default handling for unknown providers
                    if routing_response.endpoint_url:
                        # Use the provided endpoint if available
                        response_data = await self._dispatch_to_endpoint(
                            routing_response.endpoint_url,
                            request_payload,
                            headers or {},
                            metrics
                        )
                    else:
                        raise HTTPException(
                            status_code=404,
                            detail=f"Unsupported model provider: {provider}"
                        )

                # Add dispatch metadata to response
                latency = (time.time() - start_time) * 1000  # Convert to milliseconds
                metrics.latency = latency

                if "_dispatch_info" not in response_data:
                    response_data["_dispatch_info"] = {
                        "model": model_id,
                        "provider": provider,
                        "latency_ms": latency,
                        "request_id": routing_response.request_id
                    }

                return response_data

        except HTTPException:
            # Re-raise HTTP exceptions
            raise
        except Exception as e:
            # Handle general errors
            latency = (time.time() - start_time) * 1000
            logger.error(f"Request error with {provider} model {model_id}: {e}")

            # Update metrics
            metrics.success = False
            metrics.latency = latency
            metrics.error_message = str(e)

            # Try fallback models if available
            if routing_response.fallback_models:
                logger.info(f"Trying fallback model due to error: {e}")
                return await self._try_fallback_models(
                    routing_response,
                    request_payload,
                    headers,
                    1  # Start with first fallback
                )

            # If no fallbacks available or all failed, raise exception
            raise HTTPException(
                status_code=503,
                detail=f"Model service unavailable: {str(e)}"
            )

        finally:
            # Log metrics
            await self._log_metrics(metrics)

    async def _dispatch_to_ollama(
        self,
        model_id: str,
        payload: Dict[str, Any],
        metrics: RoutingMetrics
    ) -> Dict[str, Any]:
        """Dispatch a request to Ollama"""
        if not self.ollama_url:
            raise HTTPException(
                status_code=503,
                detail="Ollama URL not configured"
            )

        try:
            # Extract the actual message content
            message_content = ""
            if isinstance(payload.get("content"), str):
                message_content = payload["content"]
            elif isinstance(payload.get("prompt"), str):
                message_content = payload["prompt"]
            elif isinstance(payload.get("messages"), list) and payload["messages"]:
                # Get the last message content if it's a list
                last_message = payload["messages"][-1]
                if isinstance(last_message, dict) and "content" in last_message:
                    message_content = last_message["content"]

            # Create Ollama-compatible request
            ollama_payload = {
                "model": model_id,
                "prompt": message_content,
                "stream": False
            }

            # Add optional parameters if present
            if "parameters" in payload and isinstance(payload["parameters"], dict):
                params = payload["parameters"]
                if "temperature" in params:
                    ollama_payload["temperature"] = params["temperature"]
                if "max_tokens" in params:
                    ollama_payload["max_length"] = params["max_tokens"]

            url = f"{self.ollama_url}/api/generate"

            logger.info(f"Sending request to Ollama: {url}")
            async with self.session.post(url, json=ollama_payload) as response:
                if response.status == 200:
                    result = await response.json()

                    # Update metrics
                    metrics.success = True
                    if "prompt_eval_count" in result:
                        metrics.content_token_count = result["prompt_eval_count"]
                    if "eval_count" in result:
                        metrics.response_token_count = result["eval_count"]

                    # Format response to be more standardized
                    return {
                        "model": model_id,
                        "provider": "ollama",
                        "content": result.get("response", ""),
                        "response": result.get("response", ""),
                        "finish_reason": "stop",
                        "usage": {
                            "prompt_tokens": result.get("prompt_eval_count", 0),
                            "completion_tokens": result.get("eval_count", 0),
                            "total_tokens": result.get("prompt_eval_count", 0) + result.get("eval_count", 0)
                        }
                    }
                else:
                    error_text = await response.text()
                    logger.error(f"Ollama request failed: {error_text}")
                    metrics.success = False
                    metrics.error_message = f"HTTP {response.status}: {error_text[:100]}"

                    raise HTTPException(
                        status_code=response.status,
                        detail=f"Ollama API error: {error_text[:200]}"
                    )
        except HTTPException:
            # Re-raise HTTP exceptions
            raise
        except Exception as e:
            logger.exception(f"Error dispatching to Ollama: {e}")
            metrics.success = False
            metrics.error_message = str(e)

            raise HTTPException(
                status_code=503,
                detail=f"Ollama service error: {str(e)}"
            )

    async def _dispatch_to_endpoint(
        self,
        endpoint_url: str,
        request_payload: Dict[str, Any],
        headers: Dict[str, str],
        metrics: RoutingMetrics
    ) -> Dict[str, Any]:
        """Dispatch a request to a generic API endpoint"""
        # Add content type header if not present
        if "Content-Type" not in headers:
            headers["Content-Type"] = "application/json"

        # Add custom headers for tracking
        headers["X-Request-ID"] = metrics.request_id
        headers["X-Selected-Model"] = metrics.model_id

        # Generic dispatch to an arbitrary endpoint
        try:
            async with self.session.post(
                endpoint_url,
                json=request_payload,
                headers=headers,
                timeout=settings.REQUEST_TIMEOUT
            ) as response:
                # Parse response
                if response.status == 200:
                    response_data = await response.json()

                    # Update metrics
                    metrics.success = True

                    # Try to extract response token count
                    if "response" in response_data and isinstance(response_data["response"], str):
                        metrics.response_token_count = len(response_data["response"]) // 4

                    # Try to extract cost if provided
                    if "cost" in response_data:
                        metrics.cost = response_data["cost"]

                    return response_data
                else:
                    # Handle error response
                    error_text = await response.text()
                    logger.error(f"Model API error: {error_text}")

                    # Update metrics
                    metrics.success = False
                    metrics.error_message = f"HTTP {response.status}: {error_text[:100]}"

                    raise HTTPException(
                        status_code=response.status,
                        detail=f"Model API error: {error_text[:200]}"
                    )
        except aiohttp.ClientError as e:
            # Handle request errors
            logger.error(f"Request error: {e}")

            # Update metrics
            metrics.success = False
            metrics.error_message = str(e)

            raise HTTPException(
                status_code=503,
                detail=f"Model service unavailable: {e}"
            )
                
    async def _try_fallback_models(
        self,
        routing_response: RoutingResponse,
        request_payload: Dict[str, Any],
        headers: Dict[str, str],
        fallback_index: int
    ) -> Dict[str, Any]:
        """Try to use a fallback model"""
        if fallback_index >= len(routing_response.fallback_models):
            # No more fallbacks available
            raise HTTPException(
                status_code=503,
                detail="All fallback models failed"
            )
            
        # Get fallback model
        fallback_model = routing_response.fallback_models[fallback_index]
        
        # Create new routing response for fallback
        fallback_routing_response = RoutingResponse(
            request_id=routing_response.request_id,
            selected_model=fallback_model,
            fallback_models=routing_response.fallback_models[fallback_index+1:],
            routing_reason=f"fallback #{fallback_index} for {routing_response.selected_model}",
            selection_confidence=0.3,
            endpoint_url=f"/api/v1/models/{fallback_model}/generate",  # Basic endpoint pattern
            auth_required=routing_response.auth_required,
            additional_parameters=routing_response.additional_parameters
        )
        
        try:
            # Try with fallback model
            return await self.dispatch_request(
                fallback_routing_response,
                request_payload,
                headers
            )
        except Exception as e:
            logger.error(f"Fallback model {fallback_model} failed: {e}")
            
            # Try next fallback
            return await self._try_fallback_models(
                routing_response,
                request_payload,
                headers,
                fallback_index + 1
            )
            
    async def _log_metrics(self, metrics: RoutingMetrics):
        """Log metrics for model usage"""
        # In a production environment, you would save these metrics to your database
        # and/or send them to your monitoring system
        
        logger.info(f"Request metrics: model={metrics.model_id}, success={metrics.success}, "
                   f"latency={metrics.latency}ms, tokens_in={metrics.content_token_count}, "
                   f"tokens_out={metrics.response_token_count}, cost={metrics.cost}")
                   
        # In a real implementation, you might have:
        # await metrics_service.save_metrics(metrics)
        # or
        # await prometheus_client.record_metrics(metrics)
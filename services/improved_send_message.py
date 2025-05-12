#!/usr/bin/env python3
import requests
import json
import asyncio
import logging
from typing import Optional, Dict, Any, List, Union

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ModelRouterClient:
    """Client for interacting with the Model Router service."""
    
    def __init__(self, base_url: str):
        """Initialize the Model Router client.
        
        Args:
            base_url: Base URL for the Model Router service
        """
        self.base_url = base_url
        logger.info(f"Initialized ModelRouterClient with base URL: {base_url}")
    
    async def get_model_id_by_name(self, model_name: str, debug_mode: bool = False) -> Optional[int]:
        """Get numeric model ID from the model registry by model name.
        
        Args:
            model_name: Name of the model to find
            debug_mode: Whether to print debug information
            
        Returns:
            Numeric model ID if found, None otherwise
        """
        if model_name == "auto":
            # Auto means let the router decide
            return None
            
        try:
            # Construct model registry URL from model router URL
            # Assuming they're in the same network with standard ports
            base_url = self.base_url.replace("model-router:8080", "model-registry:8079")
            
            # If using localhost, keep the same host
            if "localhost" in self.base_url:
                base_url = self.base_url.replace("8080", "8079")
                
            if debug_mode:
                logger.info(f"Getting models from {base_url}/api/v1/models")
                
            # Get all models from registry
            response = requests.get(f"{base_url}/api/v1/models", timeout=5)
            
            if response.status_code == 200:
                models = response.json()
                
                # Find model by name
                for model in models:
                    if model["name"] == model_name:
                        model_id = model["id"]
                        if debug_mode:
                            logger.info(f"Found model {model_name} with ID {model_id}")
                        return model_id
                        
                # Model not found
                logger.warning(f"Model {model_name} not found in registry")
                return None
            else:
                logger.error(f"Error getting models: {response.status_code} - {response.text}")
                return None
        except Exception as e:
            logger.error(f"Exception getting model ID: {str(e)}")
            return None
    
    async def process_message(
        self, 
        message: str, 
        model_id: Optional[str] = None, 
        user_id: str = "streamlit_user",
        debug_mode: bool = False
    ) -> Dict[str, Any]:
        """Process a message through the Model Router service or directly through Ollama.
        
        Args:
            message: The message to process
            model_id: Optional model name or ID to use for processing
            user_id: User ID for the request
            debug_mode: Whether to log debug information
            
        Returns:
            Response data from the model
        """
        # For Ollama models, use direct Ollama API instead of model router
        if model_id and any(prefix in model_id.lower() for prefix in ["llama", "tiny", "code", "ollama"]):
            if debug_mode:
                logger.info(f"Using direct Ollama API for model: {model_id}")
            return await self.call_ollama_directly(message, model_id, debug_mode)
        
        # For other models, use the model router
        # Create a unique request ID
        import time
        request_id = f"streamlit_{int(time.time())}"
        
        # Create request payload
        if debug_mode:
            logger.info(f"Creating request payload for message: {message[:50]}...")
            
        payload = {
            "id": request_id,
            "task_type": "chat",
            "content": [
                {
                    "type": "text",
                    "content": message,
                    "metadata": {}
                }
            ],
            "context": {
                "user_id": user_id,
                "session_id": f"session_{user_id}_{int(time.time())}",
                "require_local_inference": True
            }
        }
        
        # Add model selection if provided
        if model_id and model_id != "auto":
            # Try to get numeric ID if string name is provided
            numeric_id = await self.get_model_id_by_name(model_id, debug_mode)
            
            if numeric_id is not None:
                if debug_mode:
                    logger.info(f"Using numeric model ID: {numeric_id}")
                payload["model_preference"] = str(numeric_id)
            else:
                # Fallback to name
                if debug_mode:
                    logger.info(f"Numeric ID not found, using name: {model_id}")
                payload["model_preference"] = model_id
            
        if debug_mode:
            logger.info(f"Request payload: {json.dumps(payload)}")
            
        try:
            # Make request to model router
            if debug_mode:
                logger.info(f"Sending request to {self.base_url}/api/v1/process")
            
            # Use direct HTTP request instead of asyncio for simplicity
            response = requests.post(
                f"{self.base_url}/api/v1/process",
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=60  # Longer timeout for model inference
            )
            
            if debug_mode:
                logger.info(f"Response status code: {response.status_code}")
                
            if response.status_code == 200:
                result = response.json()
                if debug_mode:
                    logger.info(f"Response: {json.dumps(result)}")
                return result
            else:
                error_message = f"Error from Model Router: {response.status_code} - {response.text}"
                logger.error(error_message)
                
                # If model router failed, try direct Ollama access as fallback for OpenAI models
                if model_id and "gpt" in model_id.lower():
                    logger.info(f"Model router failed, falling back to TinyLlama")
                    return await self.call_ollama_directly(message, "tinyllama", debug_mode)
                    
                return {"error": error_message}
                
        except Exception as e:
            error_message = f"Exception calling Model Router: {str(e)}"
            logger.error(error_message)
            
            # If model router failed, try direct Ollama access as fallback
            logger.info(f"Model router exception, falling back to TinyLlama")
            return await self.call_ollama_directly(message, "tinyllama", debug_mode)
    
    async def call_ollama_directly(
        self, 
        message: str, 
        model_name: str = "tinyllama", 
        debug_mode: bool = False
    ) -> Dict[str, Any]:
        """Call Ollama directly for reliable LLM inference.
        
        Args:
            message: The message to send to Ollama
            model_name: The name of the Ollama model to use
            debug_mode: Whether to log debug information
            
        Returns:
            Response data from Ollama
        """
        # Use different Ollama endpoints depending on environment
        # For container environment
        ollama_endpoints = [
            "http://alfred-ollama:11434",  # Preferred container name
            "http://ollama:11434",         # Alternative container name 
            "http://localhost:11434"       # Local development
        ]
        
        # Normalize model name - remove provider prefix if any
        if ":" in model_name:
            model_name = model_name.split(":")[-1]
            
        # Special case for OpenAI models - use TinyLlama as fallback
        if "gpt" in model_name.lower():
            model_name = "tinyllama"
        
        # Create request payload
        payload = {
            "model": model_name,
            "messages": [
                {"role": "user", "content": message}
            ],
            "stream": False  # Disable streaming for simplicity
        }
        
        if debug_mode:
            logger.info(f"Trying to send request to Ollama with payload: {json.dumps(payload)}")
        
        # Try each endpoint in order
        for ollama_url in ollama_endpoints:
            if debug_mode:
                logger.info(f"Trying Ollama endpoint: {ollama_url}")
                
            try:
                # Send request to Ollama
                response = requests.post(
                    f"{ollama_url}/api/chat",
                    json=payload,
                    headers={"Content-Type": "application/json"},
                    timeout=15  # Shorter timeout to try multiple endpoints
                )
                
                if debug_mode:
                    logger.info(f"Response status code from {ollama_url}: {response.status_code}")
                    
                if response.status_code == 200:
                    result = response.json()
                    if debug_mode:
                        logger.info(f"Successful response from {ollama_url}")
                        
                    # Extract message content for consistent output format
                    if "message" in result and "content" in result["message"]:
                        return {"response": result["message"]["content"]}
                    return {"response": str(result)}
                    
                # If this endpoint failed, try the next one
                
            except Exception as e:
                if debug_mode:
                    logger.info(f"Error with {ollama_url}: {str(e)}")
                # Try the next endpoint
                continue
        
        # If we get here, all endpoints failed
        error_message = "Failed to connect to Ollama using any available endpoint"
        logger.error(error_message)
        return {"error": error_message}

def create_model_router_client(base_url: str) -> ModelRouterClient:
    """Create a Model Router client.
    
    Args:
        base_url: Base URL for the Model Router service
        
    Returns:
        ModelRouterClient instance
    """
    return ModelRouterClient(base_url)
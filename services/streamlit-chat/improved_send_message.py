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
    
    async def process_message(
        self, 
        message: str, 
        model_id: Optional[str] = None, 
        user_id: str = "streamlit_user",
        debug_mode: bool = False
    ) -> Dict[str, Any]:
        """Process a message through the Model Router service.
        
        Args:
            message: The message to process
            model_id: Optional model ID to use for processing
            user_id: User ID for the request
            debug_mode: Whether to log debug information
            
        Returns:
            Response data from the model
        """
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
        if model_id:
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
                return {"error": error_message}
                
        except Exception as e:
            error_message = f"Exception calling Model Router: {str(e)}"
            logger.error(error_message)
            return {"error": error_message}
    
    async def call_ollama_directly(
        self, 
        message: str, 
        model_name: str = "tinyllama", 
        debug_mode: bool = False
    ) -> Dict[str, Any]:
        """Call Ollama directly for testing purposes.
        
        Args:
            message: The message to send to Ollama
            model_name: The name of the Ollama model to use
            debug_mode: Whether to log debug information
            
        Returns:
            Response data from Ollama
        """
        # Ollama endpoint
        ollama_url = "http://localhost:11434"
        
        # Create request payload
        payload = {
            "model": model_name,
            "messages": [
                {"role": "user", "content": message}
            ],
            "stream": False  # Disable streaming for simplicity
        }
        
        if debug_mode:
            logger.info(f"Sending request to {ollama_url}/api/chat with payload: {json.dumps(payload)}")
        
        try:
            # Send request to Ollama
            response = requests.post(
                f"{ollama_url}/api/chat",
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
                    
                # Extract message content for consistent output format
                if "message" in result and "content" in result["message"]:
                    return {"response": result["message"]["content"]}
                return {"response": str(result)}
            else:
                error_message = f"Error from Ollama: {response.status_code} - {response.text}"
                logger.error(error_message)
                return {"error": error_message}
                
        except Exception as e:
            error_message = f"Exception calling Ollama: {str(e)}"
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
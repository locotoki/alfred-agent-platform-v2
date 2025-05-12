"""
Client for interacting with the Model Router service.
This module provides functionality to route requests to the appropriate LLM model.
"""

import os
import json
import requests
from typing import Dict, Any, Optional, List
import structlog

logger = structlog.get_logger(__name__)

class ModelClient:
    """Client for interacting with the Model Router service."""
    
    def __init__(self, base_url: Optional[str] = None):
        """
        Initialize the Model Router client.

        Args:
            base_url: Base URL for the Model Router service. Defaults to the MODEL_ROUTER_URL
                      environment variable, or http://localhost:8080 if not set.
        """
        self.base_url = base_url or os.environ.get("MODEL_ROUTER_URL", "http://localhost:8080")
        
    def process_with_model(
        self,
        content: str,
        model: Optional[str] = None,
        task_type: str = "chat",
        parameters: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Process content with a specified model or automatically route to the best model.

        Args:
            content: The content to process (can be text, json, etc.)
            model: Optional model ID to use. If None, will use router to select best model.
            task_type: The type of task (chat, completion, summarization, etc.)
            parameters: Optional parameters for the model

        Returns:
            Response from the model

        Raises:
            Exception: If there's an error communicating with the Model Router service
        """
        try:
            # First check if Model Router service is available
            try:
                requests.get(f"{self.base_url}/health", timeout=1)
                model_router_available = True
            except:
                model_router_available = False

            # If Model Router is not available, provide a fallback response
            if not model_router_available:
                logger.warning("Model Router service not available. Using fallback response.")
                return {
                    "content": f"I received your message about '{content[:50]}{'...' if len(content) > 50 else ''}'. The Model Router service is not currently available, so I'm providing a basic response.",
                    "response": f"I've received your message, but the AI model service is currently initializing. Please try again later or contact your administrator if this persists.",
                    "_routing": {
                        "model": "fallback",
                        "routing_reason": "model_router_unavailable",
                        "confidence": 0.0,
                        "request_id": str(parameters.get("task_id", "unknown")) if parameters else "unknown"
                    }
                }

            url = f"{self.base_url}/api/v1/process"

            # Build the request payload
            payload = {
                "content": content,
                "task_type": task_type,
                "parameters": parameters or {}
            }

            if model and model != "auto":
                payload["model"] = model

            # Call the Model Router service
            response = requests.post(
                url,
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=5
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                error_msg = f"Error from Model Router: {response.status_code} - {response.text}"
                logger.error("model_router_error", error=error_msg)
                raise Exception(error_msg)
                
        except requests.RequestException as e:
            logger.error("model_router_request_failed", error=str(e))
            raise Exception(f"Failed to communicate with Model Router: {str(e)}")
            
    def get_available_models(self) -> List[Dict[str, Any]]:
        """
        Get a list of all available models.
        
        Returns:
            List of model configurations
            
        Raises:
            Exception: If there's an error communicating with the Model Router service
        """
        try:
            url = f"{self.base_url}/api/v1/models"
            
            response = requests.get(url)
            
            if response.status_code == 200:
                return response.json()
            else:
                error_msg = f"Error getting models: {response.status_code} - {response.text}"
                logger.error("get_models_error", error=error_msg)
                raise Exception(error_msg)
                
        except requests.RequestException as e:
            logger.error("get_models_request_failed", error=str(e))
            raise Exception(f"Failed to get models: {str(e)}")
            
    def get_models_for_task(self, task_type: str) -> List[Dict[str, Any]]:
        """
        Get models that support a specific task type.
        
        Args:
            task_type: The type of task (chat, completion, summarization, etc.)
            
        Returns:
            List of model configurations that support the task
            
        Raises:
            Exception: If there's an error communicating with the Model Router service
        """
        try:
            url = f"{self.base_url}/api/v1/models/task/{task_type}"
            
            response = requests.get(url)
            
            if response.status_code == 200:
                return response.json()
            else:
                error_msg = f"Error getting models for task {task_type}: {response.status_code} - {response.text}"
                logger.error("get_models_for_task_error", error=error_msg)
                raise Exception(error_msg)
                
        except requests.RequestException as e:
            logger.error("get_models_for_task_request_failed", error=str(e))
            raise Exception(f"Failed to get models for task {task_type}: {str(e)}")
#!/usr/bin/env python3
"""
Create a specialized client that directly accesses Ollama without any simulation.
This replaces the existing send_message.py to provide direct model responses.
"""

import requests
import json
import asyncio
import logging
import time
from typing import Optional, Dict, Any, List, Union

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DirectModelClient:
    """Client for directly accessing Ollama models without simulation."""
    
    def __init__(self, base_url: str = "http://localhost:11434"):
        """Initialize the model client.
        
        Args:
            base_url: Base URL for Ollama service (default: http://localhost:11434)
        """
        self.base_url = base_url
        self.ollama_endpoints = [
            "http://alfred-ollama:11434",  # Container name in Docker network
            "http://ollama:11434",         # Alternative container name
            "http://localhost:11434"       # Local development
        ]
        logger.info(f"Initialized DirectModelClient")
    
    async def process_message(
        self, 
        message: str, 
        model_id: Optional[str] = None, 
        user_id: str = "streamlit_user",
        debug_mode: bool = False
    ) -> Dict[str, Any]:
        """Process a message directly through Ollama.
        
        Args:
            message: The message to process
            model_id: The model to use (default: tinyllama)
            user_id: User ID (not used for Ollama)
            debug_mode: Whether to log debug information
            
        Returns:
            Response data with the model's response
        """
        # Default to tinyllama if no model specified
        model_name = model_id if model_id and model_id != "auto" else "tinyllama"
        
        # Clean model name
        if ":" in model_name:
            model_name = model_name.split(":")[-1]
            
        # For non-Ollama models, use tinyllama
        if not any(prefix in model_name.lower() for prefix in ["llama", "tiny", "code"]):
            if debug_mode:
                logger.info(f"Non-Ollama model {model_name}, using tinyllama instead")
            model_name = "tinyllama"
            
        if debug_mode:
            logger.info(f"Sending message to Ollama with model: {model_name}")
            
        # Create payload for Ollama
        payload = {
            "model": model_name,
            "messages": [
                {"role": "user", "content": message}
            ],
            "stream": False
        }
        
        # Try each endpoint
        for endpoint in self.ollama_endpoints:
            try:
                if debug_mode:
                    logger.info(f"Trying endpoint: {endpoint}")
                    
                # Send to Ollama
                response = requests.post(
                    f"{endpoint}/api/chat",
                    json=payload,
                    headers={"Content-Type": "application/json"},
                    timeout=30
                )
                
                if response.status_code == 200:
                    result = response.json()
                    
                    if debug_mode:
                        logger.info(f"Got successful response from {endpoint}")
                        
                    # Extract content from Ollama response
                    if "message" in result and "content" in result["message"]:
                        return {"response": result["message"]["content"]}
                    else:
                        return {"response": str(result)}
            except Exception as e:
                if debug_mode:
                    logger.info(f"Error with endpoint {endpoint}: {str(e)}")
                # Continue to next endpoint
                    
        # If all endpoints failed, return error
        return {"response": f"I tried to answer your question about '{message}' but couldn't connect to any language models. Please check Ollama is running properly."}

def create_model_router_client(base_url: str) -> DirectModelClient:
    """Create a model client - this keeps compatibility with existing code.
    
    Args:
        base_url: Base URL (ignored, always uses Ollama)
        
    Returns:
        DirectModelClient instance
    """
    return DirectModelClient()
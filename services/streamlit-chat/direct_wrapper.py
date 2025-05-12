#!/usr/bin/env python3
"""
Direct wrapper for the Streamlit chat UI to bypass simulation.
This integrates with send_message.py.
"""

import requests
import logging
import time
import json

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def process_command(message: str, model_id: str = "tinyllama", debug_mode: bool = False) -> str:
    """Process a chat message and get a real response from Ollama.
    
    Args:
        message: The message to process
        model_id: The model to use
        debug_mode: Whether to log debug information
        
    Returns:
        Response from Ollama
    """
    # List of Ollama endpoints to try
    ollama_endpoints = [
        "http://alfred-ollama:11434",
        "http://ollama:11434",
        "http://localhost:11434"
    ]
    
    # Clean model name
    if ":" in model_id:
        model_id = model_id.split(":")[-1]
        
    # Fall back to tinyllama for non-Ollama models
    if not any(prefix in model_id.lower() for prefix in ["llama", "tiny", "code"]):
        if debug_mode:
            logger.info(f"Non-Ollama model {model_id}, using tinyllama instead")
        model_id = "tinyllama"
        
    # Create payload
    payload = {
        "model": model_id,
        "messages": [
            {"role": "user", "content": message}
        ],
        "stream": False
    }
    
    if debug_mode:
        logger.info(f"Sending direct Ollama request with model {model_id}")
        
    # Try each endpoint
    for endpoint in ollama_endpoints:
        try:
            if debug_mode:
                logger.info(f"Trying Ollama endpoint: {endpoint}")
                
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
                    
                # Extract content
                if "message" in result and "content" in result["message"]:
                    return result["message"]["content"]
                else:
                    return f"Received response but couldn't extract content: {str(result)}"
        except Exception as e:
            if debug_mode:
                logger.info(f"Error with {endpoint}: {str(e)}")
            # Try next endpoint
            
    # If all failed, return error
    return f"I tried to answer your question about '{message}' but couldn't connect to any language models. Please check Ollama is running properly."

def get_help_response() -> str:
    """Get help message."""
    return """
    ## Alfred Bot Commands
    
    I can help you with various tasks through the chat interface.
    
    ### Basic Commands:
    - `help` - Show this help message
    - `ping` - Test bot responsiveness
    - `models` - List available LLM models
    
    ### Available Models:
    - TinyLlama - Lightweight LLama model
    - Llama2 - Meta's Llama 2 model
    
    > 💡 Direct model inference is enabled with Ollama
    """

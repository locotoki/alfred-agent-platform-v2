#!/usr/bin/env python3
"""
CrewAI client wrapper for the Alfred Agent Platform.
This module handles authentication and communication with the CrewAI service.
"""

import os
import json
import logging
import requests
from typing import Dict, Any, Optional

# Set up logging
logger = logging.getLogger(__name__)

def send_task(payload: Dict[str, Any]) -> Dict[str, Any]:
    """
    Send a task to the CrewAI service with proper A2A authentication.
    
    Args:
        payload: The task payload to send to CrewAI
    
    Returns:
        The response from CrewAI as a dictionary
    
    Raises:
        ValueError: If the token file is not found or cannot be read
        requests.RequestException: If the request to the CrewAI service fails
    """
    # Get configuration from environment
    crewai_endpoint = os.getenv("CREWAI_ENDPOINT", "https://crewai.prod.internal")
    token_path = os.getenv("CREWAI_A2A_JWT", "/var/run/secrets/crewai-a2a/token")
    
    # Read the JWT token from the file
    try:
        with open(token_path) as fp:
            jwt_token = fp.read().strip()
            if not jwt_token:
                raise ValueError(f"Empty token found in {token_path}")
    except (FileNotFoundError, PermissionError) as e:
        logger.error(f"Error reading token file: {e}")
        raise ValueError(f"Could not read token from {token_path}: {e}")
    
    # Set up request headers with authentication
    headers = {
        "Authorization": f"Bearer {jwt_token}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    
    # Send the request to the CrewAI service
    try:
        logger.debug(f"Sending request to {crewai_endpoint}")
        response = requests.post(
            crewai_endpoint,
            json=payload,
            headers=headers,
            timeout=10  # 10 second timeout for the request
        )
        response.raise_for_status()  # Raise an exception for HTTP errors
        return response.json()
    except requests.RequestException as e:
        logger.error(f"Error communicating with CrewAI service: {e}")
        raise

def validate_token(token_path: Optional[str] = None) -> bool:
    """
    Validate that the A2A token exists and is readable.
    
    Args:
        token_path: Optional path to the token file. If not provided, 
                    uses the default from the environment.
    
    Returns:
        True if the token exists and is readable, False otherwise
    """
    if not token_path:
        token_path = os.getenv("CREWAI_A2A_JWT", "/var/run/secrets/crewai-a2a/token")
    
    try:
        with open(token_path) as fp:
            token = fp.read().strip()
            return bool(token)  # Return True if token is not empty
    except (FileNotFoundError, PermissionError):
        return False
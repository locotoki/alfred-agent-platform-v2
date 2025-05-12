#!/usr/bin/env python3
import asyncio
import sys
import os

# Add the streamlit-chat directory to sys.path
sys.path.append(os.path.join(os.path.dirname(__file__), "streamlit-chat"))

# Import the functions from send_message.py
from send_message import create_model_router_client

async def main():
    """Test calling Ollama through the ModelRouterClient."""
    # Create the client with the URL for the running model router
    client = create_model_router_client("http://localhost:8080")
    
    # Define a test message
    message = "What can you tell me about yourself? Keep it brief."
    
    print(f"Testing direct Ollama call with message: {message}")
    
    # Call Ollama directly (skipping the model router)
    response = await client.call_ollama_directly(
        message=message,
        model_name="tinyllama",
        debug_mode=True
    )
    
    print("\nResponse from Ollama:")
    if "error" in response:
        print(f"Error: {response['error']}")
    else:
        print(response.get("response", "No response"))

if __name__ == "__main__":
    # Run the async main function
    asyncio.run(main())
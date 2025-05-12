#!/bin/bash
# Script to fix Streamlit container connections to model services

echo "Creating a direct Ollama chat handler for Streamlit..."

# Create a file that will be mounted into the container
cat > /home/locotoki/projects/alfred-agent-platform-v2/services/streamlit-chat/direct_chat.py << 'EOF'
#!/usr/bin/env python3
"""
Direct chat handler for Streamlit to bypass model router issues.
This module directly calls Ollama for chat requests.
"""

import requests
import json
import time
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def get_direct_response(message, model="tinyllama"):
    """
    Get a direct response from Ollama without going through the model router.
    
    Args:
        message: The message to send
        model: The model to use (default: tinyllama)
        
    Returns:
        The model's response
    """
    # Ollama is accessible via the container name in Docker network
    ollama_url = "http://alfred-ollama:11434"
    
    logger.info(f"Sending direct request to Ollama ({model}) at {ollama_url}")
    
    try:
        # Create request payload
        payload = {
            "model": model,
            "messages": [
                {"role": "user", "content": message}
            ],
            "stream": False
        }
        
        # Send request
        response = requests.post(
            f"{ollama_url}/api/chat",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=60
        )
        
        if response.status_code == 200:
            result = response.json()
            logger.info("Received successful response from Ollama")
            
            # Extract message content
            if "message" in result and "content" in result["message"]:
                return result["message"]["content"]
            else:
                return f"Received response from {model}, but could not extract content: {json.dumps(result)}"
        else:
            logger.error(f"Error from Ollama: {response.status_code} - {response.text}")
            return f"Error communicating with {model}: {response.status_code}"
    except Exception as e:
        logger.error(f"Exception in direct Ollama call: {str(e)}")
        return f"Exception when calling {model}: {str(e)}"

def process_joke_request():
    """Process a joke request directly with Ollama."""
    return get_direct_response("Tell me a short, funny joke")

def process_introduction_request():
    """Process an introduction request directly with Ollama."""
    return get_direct_response("Introduce yourself briefly")

def process_generic_request(message, model="tinyllama"):
    """Process a generic request directly with Ollama."""
    return get_direct_response(message, model)
EOF

# Create a quick test script for the Streamlit UI
cat > /home/locotoki/projects/alfred-agent-platform-v2/services/test-direct-chat.py << 'EOF'
#!/usr/bin/env python3
"""
Quick test for direct chat with Ollama.
"""

import sys
sys.path.append("/home/locotoki/projects/alfred-agent-platform-v2/services/streamlit-chat")

# Import the direct chat handler
from direct_chat import process_generic_request

# Get model from command line args or use default
model = sys.argv[1] if len(sys.argv) > 1 else "tinyllama"
message = sys.argv[2] if len(sys.argv) > 2 else "Tell me a joke"

print(f"Requesting response from {model} for message: {message}")
response = process_generic_request(message, model)
print("\nResponse:\n")
print(response)
EOF

# Make scripts executable
chmod +x /home/locotoki/projects/alfred-agent-platform-v2/services/streamlit-chat/direct_chat.py
chmod +x /home/locotoki/projects/alfred-agent-platform-v2/services/test-direct-chat.py

echo "Making scripts executable..."

# Update the streamlit_chat_ui.py to use direct chat handler
echo "Patching streamlit_chat_ui.py to use direct chat handler..."

# Create a backup of the original file
cp /home/locotoki/projects/alfred-agent-platform-v2/services/streamlit-chat/streamlit_chat_ui.py /home/locotoki/projects/alfred-agent-platform-v2/services/streamlit-chat/streamlit_chat_ui.py.bak

# Patch the send_message_sync function
sed -i '701s/def send_message_sync(message):$/def send_message_sync(message):\n    """Synchronous function to send messages to Alfred."""\n    try:\n        # Try direct Ollama access first\n        if st.session_state.selected_model.startswith("llama") or st.session_state.selected_model == "tinyllama":\n            from direct_chat import process_generic_request\n            model = st.session_state.selected_model\n            if st.session_state.debug_mode:\n                st.sidebar.write(f"Using direct Ollama access with model: {model}")\n            return process_generic_request(message, model)\n    except Exception as e:\n        if st.session_state.debug_mode:\n            st.sidebar.write(f"Error in direct Ollama access: {str(e)}")\n        # Continue with normal flow\n        pass\n        \n    # Original function body follows/' /home/locotoki/projects/alfred-agent-platform-v2/services/streamlit-chat/streamlit_chat_ui.py

echo "Recreating the Streamlit UI container..."

# Use docker-compose to recreate the UI container
cd /home/locotoki/projects/alfred-agent-platform-v2
docker-compose stop ui-chat
docker-compose rm -f ui-chat
docker-compose up -d ui-chat

echo "Done! Changes applied. The Streamlit UI should now connect directly to Ollama for models like TinyLlama and Llama2."
echo "Access the UI at http://localhost:8502"
echo "1. Select 'ollama' provider"
echo "2. Choose 'TinyLlama' or 'Llama2'"
echo "3. Test with a message like 'Tell me a joke'"
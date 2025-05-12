#!/bin/bash
# Script to fix the Streamlit UI to use direct Ollama access without simulation

echo "Fixing Streamlit UI to use direct Ollama access..."

# Copy our direct implementation to the send_message.py location
cp /home/locotoki/projects/alfred-agent-platform-v2/services/direct-ollama-access.py /home/locotoki/projects/alfred-agent-platform-v2/services/streamlit-chat/send_message.py

# Create an improved wrapper script for streamlit_chat_ui.py to bypass simulation
cat > /home/locotoki/projects/alfred-agent-platform-v2/services/streamlit-chat/direct_wrapper.py << 'EOF'
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
EOF

# Copy the direct wrapper to the container
echo "Copying files to container..."
docker cp /home/locotoki/projects/alfred-agent-platform-v2/services/streamlit-chat/send_message.py ui-chat:/app/
docker cp /home/locotoki/projects/alfred-agent-platform-v2/services/streamlit-chat/direct_wrapper.py ui-chat:/app/

# Create a patch to modify streamlit_chat_ui.py
cat > /home/locotoki/projects/alfred-agent-platform-v2/services/streamlit-chat/ui_patch.py << 'EOF'
#!/usr/bin/env python3
"""
Patch the streamlit_chat_ui.py file to use direct Ollama access.
"""

import os
import re

def patch_streamlit_chat_ui():
    """Patch the streamlit_chat_ui.py file."""
    # Path to the file
    file_path = "/app/streamlit_chat_ui.py"
    
    # Read the file
    with open(file_path, "r") as f:
        content = f.read()
    
    # Replace the process_command function
    pattern = r"def process_command\(message: str\) -> str:.*?return send_message\(command\)"
    replacement = """def process_command(message: str) -> str:
    """Bypass simulation and get real responses from Ollama."""
    from direct_wrapper import process_command as direct_process
    
    # Get selected model from session state
    model = st.session_state.selected_model
    debug = st.session_state.debug_mode
    
    # Process using direct Ollama access
    return direct_process(message, model, debug)"""
    
    # Use regex with DOTALL to match across multiple lines
    new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    # Write the modified content back
    with open(file_path, "w") as f:
        f.write(new_content)
    
    print("Successfully patched streamlit_chat_ui.py")

if __name__ == "__main__":
    patch_streamlit_chat_ui()
EOF

# Run the patch inside the container
echo "Patching streamlit_chat_ui.py in the container..."
docker cp /home/locotoki/projects/alfred-agent-platform-v2/services/streamlit-chat/ui_patch.py ui-chat:/app/
docker exec ui-chat python /app/ui_patch.py

# Restart the container
echo "Restarting the Streamlit container..."
docker restart ui-chat

echo "Fix complete! The Streamlit UI has been updated to use direct Ollama access."
echo "When you send a message, it will be sent directly to Ollama."
echo "Please test by accessing http://localhost:8502 and selecting the 'ollama' provider with 'TinyLlama' model."
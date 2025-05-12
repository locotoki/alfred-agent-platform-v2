#!/bin/bash
# Script to update the Streamlit container with the fixed code

echo "Updating Streamlit container with improved messaging system..."

# Copy the improved implementation to the target location
cp /home/locotoki/projects/alfred-agent-platform-v2/services/improved_send_message.py /home/locotoki/projects/alfred-agent-platform-v2/services/streamlit-chat/send_message.py

# Copy the updated send_message.py to the container
echo "Copying updated send_message.py to container..."
docker cp /home/locotoki/projects/alfred-agent-platform-v2/services/streamlit-chat/send_message.py ui-chat:/app/

# Restart the container
echo "Restarting the Streamlit container..."
docker restart ui-chat

echo "Update complete! The Streamlit UI should now:
- Work with OpenAI models through the model router 
- Work with Ollama models through direct Ollama API
- Fall back to TinyLlama if a model is not available
- Support multiple Ollama endpoints for reliability"
echo "Please test by accessing http://localhost:8502 and selecting a model."
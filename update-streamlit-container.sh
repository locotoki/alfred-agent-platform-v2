#!/bin/bash
# Script to update the Streamlit container with the improved code

echo "Updating Streamlit container with improved model router client..."

# Copy the updated send_message.py to the container
echo "Copying updated send_message.py to container..."
docker cp /home/locotoki/projects/alfred-agent-platform-v2/services/streamlit-chat/send_message.py ui-chat:/app/

# Restart the container
echo "Restarting the Streamlit container..."
docker restart ui-chat

echo "Update complete! The Streamlit UI should now use numeric model IDs."
echo "Please test by accessing http://localhost:8502 and selecting a model."
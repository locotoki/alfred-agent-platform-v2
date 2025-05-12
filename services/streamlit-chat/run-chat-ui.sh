#!/bin/bash
# Script to run the Streamlit chat interface for the Alfred platform

# Load environment variables from .env if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Set default API URL - points to the enhanced Slack bot API
export ALFRED_API_URL=${ALFRED_API_URL:-"http://localhost:8011"}

echo "Starting Streamlit Chat Interface..."
echo "Using Alfred API URL: $ALFRED_API_URL"

# Install required packages if needed
pip install streamlit requests

# Run the Streamlit application
echo "Starting Streamlit server on port 8501..."
streamlit run streamlit_chat_ui.py
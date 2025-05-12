#!/bin/bash

echo "Starting Alfred Streamlit Chat UI in development mode..."

# Set default environment variables
export ALFRED_API_URL="${ALFRED_API_URL:-http://localhost:8011}"

echo "Using Alfred API URL: $ALFRED_API_URL"

# Install dependencies if needed
pip install -r requirements.txt

# Start Streamlit
streamlit run streamlit_chat_ui.py
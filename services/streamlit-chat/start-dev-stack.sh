#!/bin/bash

# Start the streamlit chat and alfred-bot services in development mode

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo "ngrok is required but not installed. Please install it first."
    echo "Visit: https://ngrok.com/download"
    exit 1
fi

echo "Starting Alfred development stack with Streamlit Chat UI..."

# Set environment variables
export SLACK_BOT_TOKEN=${SLACK_BOT_TOKEN:-"xoxb-your-token-here"}
export SLACK_SIGNING_SECRET=${SLACK_SIGNING_SECRET:-"your-signing-secret-here"}
export ALFRED_API_URL="http://localhost:8011"

# Start Redis if not already running
if ! docker ps | grep -q redis; then
    echo "Starting Redis container..."
    docker run -d --name alfred-redis -p 6379:6379 redis:alpine
    export REDIS_URL="redis://localhost:6379"
else
    echo "Redis is already running."
    export REDIS_URL="redis://localhost:6379"
fi

# Start Alfred Bot in background
cd $(dirname "$0")/../../services/alfred-bot
echo "Starting Alfred Bot service..."
./start-slackbot-dev.sh &
ALFRED_PID=$!

# Wait for Alfred Bot to start
echo "Waiting for Alfred Bot to be ready..."
sleep 5

# Start Streamlit in foreground
cd $(dirname "$0")
echo "Starting Streamlit Chat UI..."
./start-dev.sh

# When Streamlit exits, kill the Alfred Bot process
kill $ALFRED_PID
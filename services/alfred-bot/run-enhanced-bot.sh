#!/bin/bash
# Script to run the enhanced Slack bot with proper environment variables

# Load environment variables from .env if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Set default values for required environment variables if not set
export SLACK_BOT_TOKEN=${SLACK_BOT_TOKEN:-"xoxb-your-slack-bot-token"}
export SLACK_SIGNING_SECRET=${SLACK_SIGNING_SECRET:-"your-slack-signing-secret"}
export REDIS_URL=${REDIS_URL:-"redis://localhost:6379/0"}
export DATABASE_URL=${DATABASE_URL:-"postgresql://postgres:password@localhost:5432/postgres"}
export GCP_PROJECT_ID=${GCP_PROJECT_ID:-"alfred-agent-platform"}

echo "Starting Enhanced Slack Bot..."
echo "Using Redis URL: $REDIS_URL"

# Install required packages if needed
pip install fastapi uvicorn slack_bolt redis structlog asyncio python-dotenv

# Run the application with uvicorn
echo "Starting uvicorn server on port 8011..."
uvicorn enhanced_slack_bot:app --host 0.0.0.0 --port 8011 --reload
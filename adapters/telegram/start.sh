#!/bin/bash
# Simple startup script for the Telegram adapter

set -e

echo "Starting Telegram adapter service..."

# Set default environment variables if not already set
export ALFRED_LOG_LEVEL=${ALFRED_LOG_LEVEL:-INFO}
export PORT=${PORT:-8080}

# Check if TELEGRAM_BOT_TOKEN is set
if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
    echo "WARNING: TELEGRAM_BOT_TOKEN is not set!"
    echo "The adapter will start but won't be able to connect to Telegram."
fi

# Optional: Set webhook URL if provided
if [ ! -z "$WEBHOOK_URL" ]; then
    echo "Setting webhook URL to $WEBHOOK_URL"
    # Here you could add code to register the webhook with Telegram Bot API
fi

# Start the application
echo "Starting uvicorn server on 0.0.0.0:$PORT"
exec uvicorn app:app --host 0.0.0.0 --port $PORT

#!/bin/bash
# start-slackbot-dev.sh - Development script for Alfred Slack Bot with ngrok

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}
   █████╗ ██╗     ███████╗██████╗ ███████╗██████╗     ██████╗  ██████╗ ████████╗
  ██╔══██╗██║     ██╔════╝██╔══██╗██╔════╝██╔══██╗    ██╔══██╗██╔═══██╗╚══██╔══╝
  ███████║██║     █████╗  ██████╔╝█████╗  ██║  ██║    ██████╔╝██║   ██║   ██║   
  ██╔══██║██║     ██╔══╝  ██╔══██╗██╔══╝  ██║  ██║    ██╔══██╗██║   ██║   ██║   
  ██║  ██║███████╗██║     ██║  ██║███████╗██████╔╝    ██████╔╝╚██████╔╝   ██║   
  ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝╚══════╝╚═════╝     ╚═════╝  ╚═════╝    ╚═╝   
${NC}"

echo -e "${YELLOW}Starting Alfred Slack Bot for Development with ngrok${NC}"

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo -e "${RED}ngrok not found. Please install ngrok first:${NC}"
    echo "Visit https://ngrok.com/download or run:"
    echo "  npm install ngrok -g  # using npm"
    echo "  brew install ngrok    # using Homebrew on macOS"
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f ".env.slackbot" ]; then
    echo -e "${YELLOW}Creating .env.slackbot file...${NC}"
    cat > .env.slackbot << EOF
# Slack Bot Configuration
SLACK_BOT_TOKEN=xoxb-your-token-here
SLACK_SIGNING_SECRET=your-signing-secret-here
SLACK_APP_TOKEN=xapp-your-app-level-token-here  # For socket mode if needed

# Redis Configuration
REDIS_URL=redis://redis:6379

# Supabase Configuration
DATABASE_URL=postgresql://postgres:your-super-secret-password@supabase-db:5432/postgres
SUPABASE_URL=http://supabase-rest:3000
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiZXhwIjoxNzQ5NTM2MTMwfQ.EDf3DT0Zl6qQbrLIQLwAXRWAN5kaJ5mvlAh1jm0CY-o

# Google Cloud Configuration
GCP_PROJECT_ID=alfred-agent-platform
PUBSUB_EMULATOR_HOST=pubsub-emulator:8085
EOF
    echo -e "${RED}Please edit .env.slackbot file and add your Slack tokens before continuing.${NC}"
    exit 1
fi

# Load environment variables from .env.slackbot
source .env.slackbot

# Check if SLACK_BOT_TOKEN is still the default
if [[ "$SLACK_BOT_TOKEN" == "xoxb-your-token-here" ]]; then
    echo -e "${RED}Please edit .env.slackbot file and add your Slack tokens before continuing.${NC}"
    exit 1
fi

# Kill any existing ngrok processes
pkill -f ngrok || true

# Start ngrok in the background
echo -e "${YELLOW}Starting ngrok...${NC}"
ngrok http 8011 > /dev/null &
NGROK_PID=$!

# Wait for ngrok to start
echo -e "${YELLOW}Waiting for ngrok to start...${NC}"
sleep 3

# Get ngrok URL
echo -e "${YELLOW}Getting ngrok URL...${NC}"
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"[^"]*' | sed 's/"public_url":"//g')

if [ -z "$NGROK_URL" ]; then
    echo -e "${RED}Failed to get ngrok URL. Make sure ngrok is running.${NC}"
    kill $NGROK_PID
    exit 1
fi

echo -e "${GREEN}ngrok URL: ${NGROK_URL}${NC}"
echo -e "${GREEN}Use this URL for Slack's Event Subscriptions: ${NGROK_URL}/slack/events${NC}"

# Print instructions
echo -e "${BLUE}---------------------------------------------------------------${NC}"
echo -e "${YELLOW}Slack Configuration Instructions:${NC}"
echo "1. Go to https://api.slack.com/apps"
echo "2. Select your Alfred bot app"
echo "3. Go to 'Event Subscriptions' and enable events"
echo "4. Set the Request URL to: ${NGROK_URL}/slack/events"
echo "5. Subscribe to bot events: message.im, app_mention"
echo "6. Go to 'Slash Commands' and update the /alfred command URL"
echo "7. Save changes"
echo -e "${BLUE}---------------------------------------------------------------${NC}"

# Start the bot
echo -e "${YELLOW}Starting Alfred Slack Bot...${NC}"
cd ../.. # Assuming running from services/alfred-bot directory
export SLACK_BOT_TOKEN=$SLACK_BOT_TOKEN
export SLACK_SIGNING_SECRET=$SLACK_SIGNING_SECRET
export SLACK_APP_TOKEN=$SLACK_APP_TOKEN

python -m uvicorn services.alfred-bot.app.main:app --reload --host 0.0.0.0 --port 8011

# Clean up ngrok when the app is terminated
kill $NGROK_PID
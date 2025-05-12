#!/bin/bash
# check-slackbot.sh - Diagnostic script for the Slack bot

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Alfred Slack Bot Diagnostic Tool${NC}"
echo "====================================="

# Check if Slack bot is running
echo -e "${YELLOW}Checking if Slack bot is running...${NC}"
if curl -s http://localhost:8011/health > /dev/null; then
  echo -e "${GREEN}✅ Slack bot is running.${NC}"
  HEALTH_OUTPUT=$(curl -s http://localhost:8011/health)
  echo -e "Health response: $HEALTH_OUTPUT"
else
  echo -e "${RED}❌ Slack bot is not running or not responding.${NC}"
fi

# Check if ngrok is running
echo -e "\n${YELLOW}Checking if ngrok is running...${NC}"
if curl -s http://localhost:4040/api/tunnels > /dev/null; then
  echo -e "${GREEN}✅ ngrok is running.${NC}"
  NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"[^"]*' | sed 's/"public_url":"//g')
  echo -e "ngrok URL: $NGROK_URL"
  echo -e "Slack events URL: ${NGROK_URL}/slack/events"
else
  echo -e "${RED}❌ ngrok is not running.${NC}"
  echo -e "Start ngrok with: ngrok http 8011"
fi

# Check environment variables
echo -e "\n${YELLOW}Checking environment variables...${NC}"
if [ -z "$SLACK_BOT_TOKEN" ]; then
  echo -e "${RED}❌ SLACK_BOT_TOKEN is not set.${NC}"
else
  echo -e "${GREEN}✅ SLACK_BOT_TOKEN is set.${NC}"
fi

if [ -z "$SLACK_SIGNING_SECRET" ]; then
  echo -e "${RED}❌ SLACK_SIGNING_SECRET is not set.${NC}"
else
  echo -e "${GREEN}✅ SLACK_SIGNING_SECRET is set.${NC}"
fi

if [ -z "$REDIS_URL" ]; then
  echo -e "${YELLOW}⚠️ REDIS_URL is not set, using default: redis://redis:6379${NC}"
else
  echo -e "${GREEN}✅ REDIS_URL is set: $REDIS_URL${NC}"
fi

if [ -z "$DATABASE_URL" ]; then
  echo -e "${RED}❌ DATABASE_URL is not set.${NC}"
else
  echo -e "${GREEN}✅ DATABASE_URL is set.${NC}"
fi

# Check Redis connection (if available)
echo -e "\n${YELLOW}Checking Redis connection...${NC}"
if command -v redis-cli > /dev/null && [ -n "$REDIS_URL" ]; then
  REDIS_HOST=$(echo $REDIS_URL | sed -E 's/redis:\/\/([^:]+):.*/\1/')
  REDIS_PORT=$(echo $REDIS_URL | sed -E 's/redis:\/\/[^:]+:([0-9]+).*/\1/')
  
  if redis-cli -h $REDIS_HOST -p $REDIS_PORT ping > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Redis connection successful.${NC}"
  else
    echo -e "${RED}❌ Redis connection failed.${NC}"
  fi
else
  echo -e "${YELLOW}⚠️ redis-cli not available or REDIS_URL not set, skipping Redis check.${NC}"
fi

# Test Slack events endpoint
echo -e "\n${YELLOW}Testing Slack events endpoint...${NC}"
if curl -s http://localhost:8011/slack/events -d '{"test":"data"}' -H "Content-Type: application/json" > /dev/null; then
  echo -e "${GREEN}✅ Slack events endpoint is responding.${NC}"
else
  echo -e "${RED}❌ Slack events endpoint is not responding.${NC}"
fi

# Provide troubleshooting tips
echo -e "\n${BLUE}Troubleshooting Tips:${NC}"
echo -e "1. If the bot is not running, start it with ./start-slackbot-dev.sh"
echo -e "2. If ngrok is not running, start it with ngrok http 8011"
echo -e "3. Set environment variables in .env.slackbot file"
echo -e "4. Verify Slack App configuration at https://api.slack.com/apps"
echo -e "5. Check logs with docker logs alfred-agent-platform-v2-alfred-bot-1"

echo -e "\n${GREEN}Diagnostic completed.${NC}"
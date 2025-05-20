#\!/bin/bash
# setup-dev-env.sh - Simplified environment setup for Alfred Agent Platform v2
# Created by Claude Code

# Text formatting
BOLD=$(tput bold)
NORM=$(tput sgr0)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)

echo -e "${BLUE}${BOLD}Alfred Agent Platform v2 - Development Environment Setup${NORM}"
echo -e "${YELLOW}This script will create a clean .env.local file for local development${NORM}"
echo

# Check if .env.local already exists
if [ -f .env.local ]; then
  echo -e "${YELLOW}An existing .env.local file was found.${NORM}"
  read -p "Do you want to create a new one? This will backup the current file. (y/n): " create_new
  if [[ $create_new =~ ^[Yy]$ ]]; then
    cp .env.local .env.local.backup-$(date +%Y%m%d%H%M%S)
    echo -e "${GREEN}Backed up existing .env.local${NORM}"
  else
    echo -e "${BLUE}Keeping existing .env.local file.${NORM}"
    exit 0
  fi
fi

# Use the example file as base
if [ -f .env.example ]; then
  cp .env.example .env.local
  echo -e "${GREEN}Created .env.local from .env.example template.${NORM}"
else
  echo -e "${RED}Error: .env.example not found. Cannot create .env.local${NORM}"
  exit 1
fi

# Prompt for essential variables
echo
echo -e "${BLUE}${BOLD}Please enter values for essential variables:${NORM}"
echo -e "${YELLOW}(Press Enter to keep default values)${NORM}"
echo

# Database configuration
read -p "PostgreSQL Password [your-super-secret-password]: " db_password
if [ -n "$db_password" ]; then
  sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$db_password/" .env.local
  sed -i "s < /dev/null | postgresql://postgres:your-super-secret-password@|postgresql://postgres:$db_password@|" .env.local
fi

# API Keys
read -p "OpenAI API Key: " openai_key
if [ -n "$openai_key" ]; then
  sed -i "s/^ALFRED_OPENAI_API_KEY=.*/ALFRED_OPENAI_API_KEY=$openai_key/" .env.local
fi

read -p "YouTube API Key (for Social Intel Agent): " youtube_key
if [ -n "$youtube_key" ]; then
  sed -i "s/^ALFRED_YOUTUBE_API_KEY=.*/ALFRED_YOUTUBE_API_KEY=$youtube_key/" .env.local
fi

# Slack Integration
echo
echo -e "${BLUE}${BOLD}Slack Integration Configuration:${NORM}"
read -p "Slack Bot Token (xoxb-*): " slack_bot_token
if [ -n "$slack_bot_token" ]; then
  sed -i "s/^SLACK_BOT_TOKEN=.*/SLACK_BOT_TOKEN=$slack_bot_token/" .env.local
fi

read -p "Slack App Token (xapp-*): " slack_app_token
if [ -n "$slack_app_token" ]; then
  sed -i "s/^SLACK_APP_TOKEN=.*/SLACK_APP_TOKEN=$slack_app_token/" .env.local
fi

read -p "Slack Signing Secret: " slack_signing_secret
if [ -n "$slack_signing_secret" ]; then
  sed -i "s/^SLACK_SIGNING_SECRET=.*/SLACK_SIGNING_SECRET=$slack_signing_secret/" .env.local
fi

# Set environment variables
sed -i "s/^ALFRED_ENVIRONMENT=.*/ALFRED_ENVIRONMENT=development/" .env.local
sed -i "s/^ALFRED_DEBUG=.*/ALFRED_DEBUG=true/" .env.local

# Create docker-compose.env.sh wrapper script
cat > docker-compose-env.sh << 'EOFWRAPPER'
#\!/bin/bash
# docker-compose-env.sh - Wrapper script for docker-compose with .env.local support

# Load both .env (for CI defaults) and .env.local (for local development)
if [ -f .env.local ]; then
  export $(grep -v '^#' .env.local | xargs)
fi

# Pass all arguments to docker-compose with both env files
docker-compose --env-file .env --env-file .env.local "$@"
EOFWRAPPER

chmod +x docker-compose-env.sh

echo
echo -e "${GREEN}${BOLD}Setup Complete\!${NORM}"
echo -e "${BLUE}Your local development environment has been configured.${NORM}"
echo
echo -e "${YELLOW}To start the platform with your local settings:${NORM}"
echo -e "  1. Start Docker daemon: ${BOLD}sudo service docker start${NORM}"
echo -e "  2. Use the wrapper script: ${BOLD}./docker-compose-env.sh -f docker-compose-clean.yml up${NORM}"
echo -e "  3. Or start specific services: ${BOLD}./docker-compose-env.sh -f docker-compose-clean.yml up redis db-postgres agent-core slack_mcp_gateway slack-adapter${NORM}"
echo
echo -e "${BLUE}You can edit .env.local anytime to update your local settings.${NORM}"

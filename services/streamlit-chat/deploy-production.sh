#!/bin/bash

# Production deployment script for Alfred Streamlit Chat UI and Alfred Bot

# Exit on errors
set -e

# Variables
ENV_FILE=".env.production"
COMPOSE_FILE="docker-compose.prod.yml"
DEPLOYMENT_LOG="deployment.log"

# Check if running with sudo/as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo or as root"
  exit 1
fi

echo "Beginning production deployment of Alfred Chat Interface..." | tee -a $DEPLOYMENT_LOG
echo "Timestamp: $(date)" | tee -a $DEPLOYMENT_LOG
echo "-------------------------------------------" | tee -a $DEPLOYMENT_LOG

# Check for environment file
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: Environment file $ENV_FILE not found!" | tee -a $DEPLOYMENT_LOG
  echo "Please create this file with the following variables:" | tee -a $DEPLOYMENT_LOG
  echo "SLACK_BOT_TOKEN=xoxb-your-token" | tee -a $DEPLOYMENT_LOG
  echo "SLACK_SIGNING_SECRET=your-signing-secret" | tee -a $DEPLOYMENT_LOG
  echo "DATABASE_URL=your-database-url" | tee -a $DEPLOYMENT_LOG
  echo "GCP_PROJECT_ID=your-gcp-project-id" | tee -a $DEPLOYMENT_LOG
  exit 1
fi

# Check Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
  echo "Docker is not installed. Please install Docker first." | tee -a $DEPLOYMENT_LOG
  exit 1
fi

if ! docker compose version &> /dev/null; then
  echo "Docker Compose is not installed. Please install Docker Compose first." | tee -a $DEPLOYMENT_LOG
  exit 1
fi

# Load environment variables
echo "Loading environment variables from $ENV_FILE..." | tee -a $DEPLOYMENT_LOG
set -a
source $ENV_FILE
set +a

# Pull latest code if in a git repository
if [ -d "../../.git" ]; then
  echo "Updating repository..." | tee -a $DEPLOYMENT_LOG
  cd ../..
  git pull
  cd - > /dev/null
fi

# Build and start services
echo "Building and starting services with Docker Compose..." | tee -a $DEPLOYMENT_LOG
docker compose -f $COMPOSE_FILE down
docker compose -f $COMPOSE_FILE build --no-cache
docker compose -f $COMPOSE_FILE up -d

# Wait for services to be healthy
echo "Waiting for services to be healthy..." | tee -a $DEPLOYMENT_LOG
for service in streamlit-chat alfred-bot redis; do
  echo "Checking $service health..." | tee -a $DEPLOYMENT_LOG
  timeout=120
  while [ $timeout -gt 0 ]; do
    if docker compose -f $COMPOSE_FILE ps $service | grep -q "(healthy)"; then
      echo "$service is healthy!" | tee -a $DEPLOYMENT_LOG
      break
    fi
    echo "Waiting for $service to become healthy... ($timeout seconds left)" | tee -a $DEPLOYMENT_LOG
    sleep 5
    timeout=$((timeout - 5))
  done
  
  if [ $timeout -le 0 ]; then
    echo "Timeout waiting for $service to become healthy!" | tee -a $DEPLOYMENT_LOG
    echo "Please check service logs with:" | tee -a $DEPLOYMENT_LOG
    echo "docker compose -f $COMPOSE_FILE logs $service" | tee -a $DEPLOYMENT_LOG
    exit 1
  fi
done

# Test the integration
echo "Testing integration between Streamlit Chat UI and Alfred Bot..." | tee -a $DEPLOYMENT_LOG
if ! docker exec $(docker compose -f $COMPOSE_FILE ps -q streamlit-chat) curl -s http://alfred-bot:8011/health | grep -q "status"; then
  echo "ERROR: Integration test failed. Alfred Bot is not responding correctly!" | tee -a $DEPLOYMENT_LOG
  exit 1
fi

# Success message
echo "-------------------------------------------" | tee -a $DEPLOYMENT_LOG
echo "Deployment successful!" | tee -a $DEPLOYMENT_LOG
echo "Streamlit Chat UI is accessible at: http://localhost:8501" | tee -a $DEPLOYMENT_LOG
echo "Alfred Bot API is accessible at: http://localhost:8011" | tee -a $DEPLOYMENT_LOG
echo "Deploy timestamp: $(date)" | tee -a $DEPLOYMENT_LOG
echo "" | tee -a $DEPLOYMENT_LOG
echo "To check logs, use:" | tee -a $DEPLOYMENT_LOG
echo "docker compose -f $COMPOSE_FILE logs -f" | tee -a $DEPLOYMENT_LOG
echo "" | tee -a $DEPLOYMENT_LOG
echo "To stop services:" | tee -a $DEPLOYMENT_LOG
echo "docker compose -f $COMPOSE_FILE down" | tee -a $DEPLOYMENT_LOG
echo "-------------------------------------------" | tee -a $DEPLOYMENT_LOG
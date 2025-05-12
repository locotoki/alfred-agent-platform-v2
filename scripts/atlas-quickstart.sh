#!/usr/bin/env bash
# Quick start script for Atlas (Infrastructure Architect Agent)
set -e

echo "🚀 Atlas Quick Start"
echo "===================="

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR/.."

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
  echo "❌ Docker is not running. Please start Docker and try again."
  exit 1
fi

# Check if services are running
if ! docker ps | grep -q "atlas-worker"; then
  echo "📦 Starting Atlas and required services..."
  docker-compose -f docker-compose.dev.yml up -d
  echo "⏳ Waiting for services to start..."
  sleep 15
else
  echo "✅ Atlas services are already running"
fi

# Check health of Atlas services
echo "🔍 Checking Atlas health..."
WORKER_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/healthz)
RAG_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8501/healthz)

if [ "$WORKER_HEALTH" != "200" ] || [ "$RAG_HEALTH" != "200" ]; then
  echo "⚠️ Atlas services are not healthy. Restarting..."
  docker-compose -f docker-compose.dev.yml restart atlas-worker rag-gateway
  echo "⏳ Waiting for services to restart..."
  sleep 10
else
  echo "✅ Atlas services are healthy"
fi

# Setup Supabase tables if needed
echo "🗄️ Setting up persistence..."
./scripts/setup_supabase.sh

# Print usage info
echo ""
echo "🎯 Atlas is ready! You can now generate architecture specifications."
echo ""
echo "💡 Example commands:"
echo "-------------------"
echo "./scripts/publish_task.sh \"Design a microservice architecture for a food delivery application\""
echo "./scripts/publish_task.sh \"Design a serverless API for a healthcare application\""
echo ""
echo "📖 For detailed usage instructions, see docs/atlas/USAGE_GUIDE.md"
echo ""

# Ask if user wants to send a test request
read -p "Would you like to send a test architecture request? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "🚀 Sending a test architecture request..."
  ./scripts/publish_task.sh "Design a simple cloud architecture with high availability"
  
  echo "⏳ Waiting for response (10 seconds)..."
  sleep 10
  
  echo "📝 Most recent architecture specification (truncated):"
  echo "----------------------------------------------------"
  echo ""
  
  # Try to get the most recent response
  if [[ -f .env.dev ]]; then
    source .env.dev
  fi
  
  RESULT=$(docker logs -n 200 alfred-agent-platform-v2-atlas-worker-1 2>&1 | grep -A 50 "# Simple Cloud Architecture" | head -n 20 || echo "Response not found yet. Check logs for complete response.")
  
  if [[ -z "$RESULT" ]]; then
    echo "Response still processing. Check logs in a moment with:"
    echo "docker logs alfred-agent-platform-v2-atlas-worker-1 | grep -A 100 \"simple cloud architecture\""
  else
    echo "$RESULT"
    echo "..."
    echo ""
    echo "For the complete response, check the logs:"
    echo "docker logs alfred-agent-platform-v2-atlas-worker-1 | grep -A 500 \"simple cloud architecture\""
  fi
fi

echo ""
echo "✨ Atlas is running and ready to use!"
echo "Run 'docker-compose -f docker-compose.dev.yml logs -f atlas-worker' to see live output"
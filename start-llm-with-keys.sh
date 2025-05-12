#!/bin/bash

set -e

# Function to check if a file exists
check_file() {
  if [ ! -f "$1" ]; then
    echo "❌ Error: File $1 not found"
    exit 1
  fi
}

# Function to add API key input
get_api_key() {
  local key_name=$1
  local env_var=$2
  local default_value=$3
  
  if [ -z "$default_value" ]; then
    read -p "Enter your $key_name API key (or press Enter to skip): " api_key
  else
    read -p "Enter your $key_name API key (or press Enter to use saved key): " api_key
    if [ -z "$api_key" ]; then
      api_key=$default_value
    fi
  fi
  
  echo $api_key
}

# Check that required files exist
check_file ".env.llm"
check_file "llm-integration-docker-compose.yml"

# Load existing API keys if available
if [ -f ".env.llm" ]; then
  source .env.llm
fi

echo "┌─────────────────────────────────────────────┐"
echo "│ Alfred Agent Platform - LLM Integration     │"
echo "│ with API Keys Configuration                  │"
echo "└─────────────────────────────────────────────┘"
echo ""

# Get API keys
OPENAI_API_KEY=$(get_api_key "OpenAI" "ALFRED_OPENAI_API_KEY" "$ALFRED_OPENAI_API_KEY")
ANTHROPIC_API_KEY=$(get_api_key "Anthropic" "ALFRED_ANTHROPIC_API_KEY" "$ALFRED_ANTHROPIC_API_KEY")

# Save API keys to .env file
cat > .env.llm << EOF
# OpenAI API Key for GPT models
ALFRED_OPENAI_API_KEY=$OPENAI_API_KEY

# Anthropic API Key for Claude models
ALFRED_ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY

# Model Registry and Router settings
MODEL_REGISTRY_URL=http://model-registry:8079
MODEL_ROUTER_URL=http://model-router:8080
EOF

echo "✅ API keys saved to .env.llm"

# Stop existing services if running
echo "Stopping existing LLM services if running..."
docker-compose -f llm-integration-docker-compose.yml down 2>/dev/null || true

# Start services with API keys
echo "🚀 Starting LLM services with API keys..."
OPENAI_API_KEY=$OPENAI_API_KEY \
ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
docker-compose -f llm-integration-docker-compose.yml up -d

echo "⏳ Waiting for services to start..."
sleep 10

# Check service health
echo "🔍 Checking service health..."

# Check Model Registry
if curl -s http://localhost:8079/health | grep -q "healthy"; then
  echo "✅ Model Registry service is healthy"
else
  echo "⚠️ Model Registry service may not be fully initialized yet"
  echo "   Check logs with: docker logs alfred-model-registry"
fi

# Check Model Router
if curl -s http://localhost:8080/health | grep -q "healthy"; then
  echo "✅ Model Router service is healthy"
else
  echo "⚠️ Model Router service may not be fully initialized yet"
  echo "   Check logs with: docker logs alfred-model-router"
fi

# Check if we should setup Ollama models
read -p "Do you want to set up Ollama models now? (y/n): " setup_ollama
if [[ "$setup_ollama" == "y" || "$setup_ollama" == "Y" ]]; then
  ./setup-ollama-models.sh
fi

# Rebuild and restart the UI to use the new configuration
echo "🔄 Rebuilding and restarting the Streamlit UI..."
cp /home/locotoki/streamlit_chat_ui.py /home/locotoki/projects/alfred-agent-platform-v2/services/streamlit-chat/streamlit_chat_ui.py
docker-compose build ui-chat
docker-compose up -d ui-chat

echo ""
echo "📋 Available services:"
echo "  - Model Registry: http://localhost:8079"
echo "  - Model Router: http://localhost:8080"
echo "  - Ollama: http://localhost:11434"
echo "  - Streamlit UI: http://localhost:8502"
echo ""
echo "✨ LLM integration with API keys completed!"
echo "   You can now use the Streamlit UI to interact with real LLM models"
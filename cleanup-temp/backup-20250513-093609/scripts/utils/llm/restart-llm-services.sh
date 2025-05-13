#!/bin/bash
# Script to restart LLM services with updated API keys

echo "Stopping any running LLM services..."
docker-compose -f llm-integration-docker-compose.yml down

echo "Starting services with updated API keys..."
# Export variables from .env.llm
export $(grep -v '^#' .env.llm | xargs)

# Start services
docker-compose -f llm-integration-docker-compose.yml up -d

echo "Services started with updated API keys."
echo "OpenAI models should now be available for inference."
echo ""
echo "To test OpenAI models:"
echo "1. Access Streamlit UI at http://localhost:8502"
echo "2. In sidebar, select 'openai' provider and a model (e.g. GPT-3.5 Turbo)"
echo "3. Enable 'Use direct model inference' and 'Debug Mode'"
echo "4. Send a test message"
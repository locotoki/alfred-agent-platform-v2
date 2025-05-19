#!/bin/bash
# Script to set up Ollama models

echo "Checking Ollama status..."
docker ps | grep llm-service

# Wait for Ollama to be fully up and running
echo "Waiting for Ollama to initialize..."
sleep 10

# Fix Ollama health check
echo "Fixing Ollama health check..."
docker exec llm-service bash -c 'echo "#!/bin/sh
wget -q --spider http://127.0.0.1:11434/api/tags || exit 1
exit 0" > /usr/local/bin/healthcheck.sh && chmod +x /usr/local/bin/healthcheck.sh'

# Pull the TinyLlama model (small and quick to download)
echo "Pulling TinyLlama model..."
docker exec llm-service ollama pull tinyllama

# Pull LLama2 model
echo "Pulling Llama2 model..."
docker exec llm-service ollama pull llama2

# Verify models are available
echo "Verifying models..."
curl -s http://localhost:11434/api/tags

echo "Setup complete!"

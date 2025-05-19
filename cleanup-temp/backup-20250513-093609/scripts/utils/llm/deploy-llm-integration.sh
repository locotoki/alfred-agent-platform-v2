#!/bin/bash
set -e

echo "┌─────────────────────────────────────────────┐"
echo "│ Alfred Agent Platform v2 - LLM Integration  │"
echo "│ Deployment Script                           │"
echo "└─────────────────────────────────────────────┘"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "❌ Error: Docker is not running or not accessible"
  echo "Please start Docker and try again"
  exit 1
fi

# Ensure network exists
if ! docker network ls | grep -q alfred-network; then
  echo "📌 Creating alfred-network..."
  docker network create alfred-network
else
  echo "✅ alfred-network already exists"
fi

# Build and start services
echo "🚀 Deploying LLM integration services..."
docker-compose -f llm-integration-docker-compose.yml up -d --build

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

# Check Ollama
if curl -s http://localhost:11434/api/tags > /dev/null; then
  echo "✅ Ollama service is ready"
else
  echo "⚠️ Ollama service may not be fully initialized yet"
  echo "   Check logs with: docker logs alfred-ollama"
fi

# Check Streamlit UI
if netstat -tuln | grep -q ":8502"; then
  echo "✅ Streamlit UI is running"
else
  echo "⚠️ Streamlit UI may not be fully initialized yet"
  echo "   Check logs with: docker logs ui-chat"
fi

echo ""
echo "📋 Available services:"
echo "  - Model Registry: http://localhost:8079"
echo "  - Model Registry API Docs: http://localhost:8079/docs"
echo "  - Model Router: http://localhost:8080"
echo "  - Model Router API Docs: http://localhost:8080/docs"
echo "  - Ollama: http://localhost:11434"
echo "  - Streamlit UI: http://localhost:8502"
echo ""

echo "📝 Next steps:"
echo "  1. Setup Ollama models using the utility script:"
echo "     ./setup-ollama-models.sh"
echo ""
echo "  2. Manually register models if needed:"
echo "     curl -X POST http://localhost:8079/api/v1/models \\"
echo "       -H \"Content-Type: application/json\" \\"
echo "       -d '{\"name\":\"model_name\",\"display_name\":\"Model Display Name\",\"provider\":\"ollama\",\"model_type\":\"chat\",\"description\":\"Description\",\"capabilities\":[{\"capability\":\"text\",\"capability_score\":0.8}]}'"
echo ""
echo "  3. Trigger model discovery (note: may have issues with automatic discovery):"
echo "     curl -X POST http://localhost:8079/api/v1/api/v1/discovery/trigger"
echo ""
echo "  4. Check available models:"
echo "     curl http://localhost:8079/api/v1/models"
echo ""
echo "  5. For full documentation, see: LLM_INTEGRATION_GUIDE.md"
echo ""

echo "✨ Deployment completed!"

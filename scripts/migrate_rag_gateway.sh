#!/usr/bin/env bash
# Script to migrate from atlas-rag-gateway to the platform-wide rag-gateway
set -e

echo "🔄 Migrating from atlas-rag-gateway to rag-gateway"
echo "================================================="

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR/.."

# 1. Stop existing services
echo "🛑 Stopping existing services..."
docker-compose -f docker-compose.dev.yml stop atlas-rag-gateway atlas-worker

# 2. Create config directories if they don't exist
echo "📁 Creating configuration directories..."
mkdir -p ./config/rag

# 3. Copy collections configuration
echo "📋 Setting up collection configuration..."
cat > ./config/rag/collections.json << 'EOF'
{
  "collections": [
    {
      "name": "general-knowledge",
      "description": "General platform knowledge shared across all agents",
      "embedding_model": "all-MiniLM-L6-v2",
      "chunk_size": 512,
      "chunk_overlap": 50
    },
    {
      "name": "architecture-knowledge",
      "description": "Specialized knowledge for the Atlas architecture agent",
      "embedding_model": "all-MiniLM-L6-v2",
      "chunk_size": 1024,
      "chunk_overlap": 128,
      "metadata_filters": [
        "architecture", 
        "infrastructure", 
        "design",
        "microservices"
      ]
    }
  ]
}
EOF

# 4. Copy access control configuration
echo "🔐 Setting up access control configuration..."
cat > ./config/rag/access_control.json << 'EOF'
{
  "policies": [
    {
      "agent": "atlas",
      "allowed_collections": ["general-knowledge", "architecture-knowledge"],
      "rate_limit_requests": 200,
      "read_only": false,
      "can_ingest": true,
      "max_tokens_per_request": 16000,
      "max_documents_per_ingest": 100
    },
    {
      "agent": "admin",
      "allowed_collections": ["*"],
      "rate_limit_requests": 500,
      "read_only": false,
      "can_ingest": true,
      "max_tokens_per_request": 20000,
      "max_documents_per_ingest": 500
    }
  ]
}
EOF

# 5. Start services with new configuration
echo "🚀 Starting services with new configuration..."
docker-compose -f docker-compose.dev.yml up -d rag-gateway atlas-worker

# 6. Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 10

# 7. Check health
echo "🔍 Checking service health..."
RAG_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8501/healthz)
WORKER_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/healthz)

if [ "$RAG_HEALTH" == "200" ] && [ "$WORKER_HEALTH" == "200" ]; then
  echo "✅ Services are healthy"
else
  echo "⚠️ Services may not be fully healthy. Please check the logs."
fi

# 8. Create collection and reindex documents if needed
echo "📚 Would you like to create the architecture-knowledge collection and index documentation? (y/n)"
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
  # Source environment for API keys
  source .env.dev
  
  # Create collection
  curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "X-API-Key: ${ATLAS_RAG_API_KEY:-atlas-key}" \
    -d '{"name": "architecture-knowledge", "description": "Architecture design patterns and knowledge"}' \
    "http://localhost:8501/collections/create"
  
  echo "✅ Collection created"
  
  # Index documentation
  echo "📂 Enter path to architecture documentation to index: "
  read -r docs_path
  if [ -d "$docs_path" ]; then
    ./scripts/index_documents.sh architecture-knowledge "$docs_path"
  else
    echo "⚠️ Invalid directory: $docs_path"
  fi
fi

echo "🎉 Migration complete!"
echo "To use the new RAG Gateway, make sure your agents use:"
echo "- RAG_URL=http://rag-gateway:8501"
echo "- RAG_API_KEY=<agent-specific-key>"
echo "- RAG_COLLECTION=<agent-specific-collection>"
echo ""
echo "For configuration and API details, see: docs/RAG_GATEWAY.md"
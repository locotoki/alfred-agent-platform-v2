#!/usr/bin/env bash
# Script to index documents into agent-specific collections
set -e

# Check arguments
if [ $# -lt 2 ]; then
  echo "Usage: $0 <collection-name> <documents-path> [file-pattern]"
  echo "Example: $0 architecture-knowledge /path/to/docs '*.md'"
  exit 1
fi

COLLECTION=$1
DOCS_PATH=$2
FILE_PATTERN=${3:-"*.md"}

# Load environment variables
if [ -f ".env.dev" ]; then
  export $(grep -v '^#' .env.dev | xargs)
elif [ -f ".env" ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Set RAG Gateway URL
RAG_URL=${RAG_URL:-"http://localhost:8501"}

# Set API key based on collection or use admin key
case "$COLLECTION" in
  "architecture-knowledge")
    API_KEY=${ATLAS_RAG_API_KEY:-"atlas-key"}
    ;;
  "alfred-personal"|"alfred-business")
    API_KEY=${ALFRED_RAG_API_KEY:-"alfred-key"}
    ;;
  "financial-knowledge")
    API_KEY=${FINANCIAL_RAG_API_KEY:-"financial-key"}
    ;;
  "legal-knowledge")
    API_KEY=${LEGAL_RAG_API_KEY:-"legal-key"}
    ;;
  "social-intel-knowledge")
    API_KEY=${SOCIAL_RAG_API_KEY:-"social-key"}
    ;;
  *)
    API_KEY=${ADMIN_RAG_API_KEY:-"admin-key"}
    ;;
esac

echo "🔍 Indexing documents for collection: $COLLECTION"
echo "📂 Documents path: $DOCS_PATH"
echo "🔎 File pattern: $FILE_PATTERN"

# Check if collection exists or create it
COLLECTION_CHECK=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "X-API-Key: $API_KEY" \
  "$RAG_URL/collections/$COLLECTION")

if [ "$COLLECTION_CHECK" == "404" ]; then
  echo "🌟 Creating collection: $COLLECTION"
  # Default metadata based on collection name
  case "$COLLECTION" in
    "architecture-knowledge")
      METADATA='{"domain": "architecture", "agent": "atlas"}'
      ;;
    "alfred-personal")
      METADATA='{"domain": "personal", "agent": "alfred"}'
      ;;
    "alfred-business")
      METADATA='{"domain": "business", "agent": "alfred"}'
      ;;
    "financial-knowledge")
      METADATA='{"domain": "financial", "agent": "financial"}'
      ;;
    "legal-knowledge")
      METADATA='{"domain": "legal", "agent": "legal"}'
      ;;
    "social-intel-knowledge")
      METADATA='{"domain": "social", "agent": "social"}'
      ;;
    *)
      METADATA='{"domain": "general"}'
      ;;
  esac
  
  curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "X-API-Key: $API_KEY" \
    -d "{\"name\": \"$COLLECTION\", \"metadata\": $METADATA}" \
    "$RAG_URL/collections/create"
  
  echo "✅ Collection created"
fi

# Process files
echo "🔄 Processing files..."
total_files=0
processed_files=0

# Process each file
find "$DOCS_PATH" -type f -name "$FILE_PATTERN" | while read -r file; do
  # Extract metadata from file path
  filename=$(basename "$file")
  dir=$(dirname "$file")
  relative_path=${file#$DOCS_PATH}
  file_ext="${filename##*.}"
  
  # Extract modification time
  mod_time=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
  
  # Default metadata
  metadata="{\"source\": \"$relative_path\", \"filename\": \"$filename\", \"modified\": $mod_time}"
  
  # Read file content
  content=$(cat "$file")
  
  # Skip empty files
  if [ -z "$content" ]; then
    echo "⚠️ Skipping empty file: $file"
    continue
  fi
  
  # Index file
  echo "📄 Indexing: $file"
  curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "X-API-Key: $API_KEY" \
    -d "{\"documents\": [{\"text\": $(echo "$content" | jq -s -R .), \"metadata\": $metadata}], \"collection\": \"$COLLECTION\"}" \
    "$RAG_URL/ingest" > /dev/null
  
  echo "  ✅ Indexed"
  
  # Track progress
  processed_files=$((processed_files + 1))
  
  # Add small delay to avoid overwhelming the server
  sleep 0.1
done

echo "🎉 Completed indexing $processed_files files into collection: $COLLECTION"

# Verify indexing
echo "🔍 Verifying collection status..."
curl -s \
  -H "X-API-Key: $API_KEY" \
  "$RAG_URL/collections/$COLLECTION/stats" | jq .
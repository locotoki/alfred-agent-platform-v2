# RAG Service - Bootstrap & Re-ranker

################################################################################

# 1. Qdrant bootstrap script – init_qdrant.sh

################################################################################

#

# Creates canonical collections for personal & business namespaces and tunes

# HNSW parameters for 768‑dim `e5-large-v2` vectors. Run once after

# `rag-stack` is started:

# docker exec rag-bootstrap ./init_qdrant.sh

#

---

init_qdrant.sh: |
#!/usr/bin/env bash
set -euo pipefail

QDRANT_HOST=${QDRANT_HOST:-qdrant}
QDRANT_PORT=${QDRANT_PORT:-6333}

create_collection() {
local name=$1
echo "Creating collection $name …"
curl -s -X PUT "[http://$](http://$/){QDRANT_HOST}:${QDRANT_PORT}/collections/${name}" \
-H 'Content-Type: application/json' \
-d '{
"vectors": {"size": 768, "distance": "Cosine"},
"hnsw_config": {"m": 16, "ef_construct": 256},
"optimizers_config": {"default_segment_number": 1},
"on_disk_payload": true
}' | jq '.status'
}

# Canonical namespaces

create_collection "rag-personal"
create_collection "rag-business"

echo "✅  Qdrant bootstrap complete."

################################################################################

# 2. Docker Compose extension – add bootstrap & GPU re‑ranker

################################################################################

# Save as docker-compose.override.rag.yml next to your existing compose files

# and start with:

# docker compose -f docker-compose.yml -f docker-compose.override.rag.yml up -d

#

version: "3.9"
services:

# -- RAG Gateway & workers are defined in earlier override file ---

rag-bootstrap:
image: curlimages/curl:8
container_name: rag-bootstrap
depends_on:
qdrant:
condition: service_started
entrypoint: ["bash", "/init_qdrant.sh"]
volumes:
- ./init_qdrant.sh:/init_qdrant.sh:ro
networks:
- alfred-network

rag-rerank-gpu:
image: [ghcr.io/jina-ai/reranker:v0.3-python](http://ghcr.io/jina-ai/reranker:v0.3-python)
container_name: rag-rerank-gpu
environment:
- MODEL_NAME=bge-reranker-large
- DEVICE=cuda
deploy:
resources:
reservations:
devices:
- driver: nvidia
count: all
capabilities: [gpu]
networks:
- alfred-network
healthcheck:
test: ["CMD", "curl", "-f", "[http://localhost:51000/healthz](http://localhost:51000/healthz)"]
interval: 30s
timeout: 5s
retries: 3

networks:
alfred-network:
external: true

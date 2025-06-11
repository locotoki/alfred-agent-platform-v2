#!/bin/bash
# Test build script for simple vector-ingest (no langchain)

set -e

echo "=== Building ML base image ==="
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

cd "$PROJECT_ROOT/base-images/python-ml"
docker build -t alfred-python-ml:latest .
echo "ML base image built successfully"

echo "=== Building vector-ingest with simple ML support ==="
cd "$PROJECT_ROOT/services/vector-ingest"
docker build -f Dockerfile.ml-simple -t vector-ingest:ml-simple .
echo "Vector-ingest simple ML image built successfully"

echo "=== Testing cold-start time ==="
# Test cold start
START_TIME=$(date +%s.%N)
docker run --rm -d --name vector-ingest-test vector-ingest:ml-simple
# Wait for health endpoint
for i in {1..30}; do
    if docker exec vector-ingest-test curl -s http://localhost:8000/health > /dev/null 2>&1; then
        END_TIME=$(date +%s.%N)
        DURATION=$(echo "$END_TIME - $START_TIME" | bc)
        echo "Cold-start time: ${DURATION}s"
        break
    fi
    sleep 0.5
done

# Get health status
echo "=== Health check response ==="
docker exec vector-ingest-test curl -s http://localhost:8000/health | python3 -m json.tool

# Cleanup
docker stop vector-ingest-test

echo "=== Image sizes ==="
docker images | grep -E "vector-ingest|alfred-python-ml" | head -5
#!/bin/bash
set -e

# Copy storage proxy to current directory
cp ../storage-proxy.js .

# Build the simple storage proxy
echo "Building storage proxy server..."
docker build -t storage-proxy:latest .

echo "Done! Now update docker-compose.unified.yml to use storage-proxy:latest"
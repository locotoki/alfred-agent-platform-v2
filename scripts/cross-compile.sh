#!/bin/bash
set -e

# Cross-compile script for database health probes
# Builds CGO-free binaries for multiple architectures

# Set build environments
export CGO_ENABLED=0

# Create output directory
mkdir -p build

echo "Building linux/amd64..."
GOOS=linux GOARCH=amd64 go build -o build/healthcheck-amd64 -ldflags="-s -w" ./cmd/healthcheck

echo "Building linux/arm64..."
GOOS=linux GOARCH=arm64 go build -o build/healthcheck-arm64 -ldflags="-s -w" ./cmd/healthcheck

echo "Done! Binaries are available in the build directory:"
ls -lh build/

# Verify they are statically linked
echo "Verifying static linking (should show 'not a dynamic executable'):"
file build/healthcheck-amd64 | grep -o "not a dynamic executable" || echo "Warning: amd64 binary may not be statically linked"
file build/healthcheck-arm64 | grep -o "not a dynamic executable" || echo "Warning: arm64 binary may not be statically linked"

#!/bin/bash
# Script to tag the release once healthcheck standardization is complete

set -euo pipefail

echo "Preparing to tag the health check standardization release..."

# Variables
RELEASE_TAG="v0.3.0-healthcheck-full"
RELEASE_MESSAGE="Health check standardization complete - All services now use v0.4.0 health check binary"

# Make sure we're on the main branch
git checkout main

# Pull latest changes
echo "Fetching latest changes from remote..."
git fetch --all
git pull

# Create and push the tag
echo "Creating release tag $RELEASE_TAG..."
git tag -a "$RELEASE_TAG" -m "$RELEASE_MESSAGE"
git push origin "$RELEASE_TAG"

echo "✅ Release tagged successfully: $RELEASE_TAG"
echo "Release message: $RELEASE_MESSAGE"
echo ""
echo "Next steps:"
echo "1. Build and push baseline images: make phase0 # or your deploy pipeline"
echo "2. Close any related project issues or cards"
echo "3. Make an announcement about the completed standardization"
#!/bin/bash
# Script to tag a release after merging a PR

set -e

VERSION="v0.2.0-phase1"
DESCRIPTION="Phase 1 metrics exporter implementation"

echo "Tagging release $VERSION: $DESCRIPTION"

# Make sure we have the latest code
git fetch --all
git checkout main
git pull origin main

# Tag the release
git tag -a "$VERSION" -m "$DESCRIPTION"

# Push the tag
git push origin "$VERSION"

echo "✅ Successfully tagged release $VERSION"
echo "The tag has been pushed to the remote repository."
echo "This will trigger CI/CD to create a release artifact."
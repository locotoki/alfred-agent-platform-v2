#!/bin/bash
# Script to promote release candidate to GA after successful canary period

set -e

# Ensure we're in the repository root
cd "$(git rev-parse --show-toplevel)"

# Confirm we're on the main branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "ERROR: Not on main branch. Please switch to main branch first."
  echo "Current branch: $CURRENT_BRANCH"
  exit 1
fi

# Get the latest changes
echo "Pulling latest changes from main..."
git pull origin main

# Tag the GA release
echo "Creating GA tag v0.8.0..."
git tag v0.8.0 -m "Phase 7C – CrewAI production with Google A2A Authentication"

# Push the tag
echo "Pushing GA tag to origin..."
git push origin v0.8.0

echo "Creating GitHub release..."
gh release create v0.8.0 \
  --title "v0.8.0: CrewAI Production with Google A2A Authentication" \
  --notes-file docs/phase7/CREWAI-CHANGELOG-ENTRY.md

echo "GA promotion complete!"
echo "The v0.8.0 release has been tagged and the GitHub release created."
echo "The CI/CD pipeline will automatically deploy to production."

echo ""
echo "Next steps:"
echo "1. Monitor the production deployment"
echo "2. Update project documentation to reflect the GA release"
echo "3. Notify stakeholders of the successful release"
echo "4. Begin planning for the next phase"

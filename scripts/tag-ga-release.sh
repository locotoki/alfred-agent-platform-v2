#!/bin/bash
# tag-ga-release.sh - Script to tag and push a GA release after successful canary monitoring

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

# Get the version to tag (default to v0.7.0 if not provided)
VERSION=${1:-v0.7.0}

# Confirm with the user
echo "About to create and push tag: $VERSION"
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Operation cancelled."
  exit 0
fi

# Create the tag
echo "Creating tag $VERSION..."
git tag "$VERSION"

# Push the tag
echo "Pushing tag $VERSION to origin..."
git push origin "$VERSION"

echo "Tag $VERSION created and pushed successfully!"
echo "Next steps:"
echo "1. Create a GitHub release with release notes"
echo "2. Trigger the deploy-prod workflow with tag '$VERSION'"
echo "3. Update branch protection rules to make slack-smoke and orchestration-integration required status checks"
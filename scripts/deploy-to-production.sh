#!/bin/bash
# deploy-to-production.sh - Script to trigger the production deployment workflow

set -e

# Ensure we're in the repository root
cd "$(git rev-parse --show-toplevel)"

# Get the version to deploy (default to v0.7.0 if not provided)
VERSION=${1:-v0.7.0}

# Confirm with the user
echo "About to trigger production deployment for tag: $VERSION"
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Operation cancelled."
  exit 0
fi

# Trigger the workflow using GitHub CLI (no parameters needed)
echo "Triggering deploy-prod workflow for tag $VERSION..."
gh workflow run deploy-prod.yml

echo "Production deployment triggered!"
echo "To monitor the deployment, check the Actions tab on GitHub:"
echo "https://github.com/locotoki/alfred-agent-platform-v2/actions/workflows/deploy-prod.yml"
echo ""
echo "NOTE: Make sure you have checked out tag $VERSION before triggering the deployment,"
echo "as the workflow will deploy the currently checked out code."
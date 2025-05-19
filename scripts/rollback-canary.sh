#!/bin/bash
# Script to roll back from a failed canary release

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

echo "Triggering rollback workflow to v0.7.0..."
gh workflow run rollback-staging.yml -f tag="v0.7.0"

echo "Rollback initiated!"
echo "The system will be rolled back to v0.7.0 in the staging environment."
echo "Please monitor the deployment to ensure the rollback completes successfully."

echo ""
echo "Next steps:"
echo "1. Update the canary issue with detailed information about the failure"
echo "2. Assign the issue to the appropriate team members for investigation"
echo "3. Create a plan to address the issues before attempting another release"

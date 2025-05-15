#!/bin/bash
# Script to check branch protection rules using GitHub CLI
# Requires gh CLI to be installed and authenticated

# Set repository as the current one if not specified
if [ -z "$REPO" ]; then
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
fi

echo "Checking branch protection rules for $REPO"

# Get branch protection rules for main branch
PROTECTION=$(gh api repos/${REPO}/branches/main/protection --jq '.')

# Check if orchestration-integration is a required status check
if echo "$PROTECTION" | grep -q "orchestration-integration"; then
  echo "✅ orchestration-integration is a required status check"
else
  echo "❌ orchestration-integration is NOT a required status check"
  echo "Please update branch protection rules in the repository settings."
  echo "Go to Settings -> Branches -> Branch protection rules -> Edit main"
  echo "Under 'Require status checks to pass before merging', add 'orchestration-integration'"
fi

# Check other important protection rules
echo ""
echo "Other important protection rules:"
echo "--------------------------------"

# Check if branch is protected
if [ -n "$PROTECTION" ]; then
  echo "✅ main branch is protected"
else
  echo "❌ main branch is NOT protected"
  exit 1
fi

# Check if required reviews are enabled
if echo "$PROTECTION" | grep -q "required_pull_request_reviews"; then
  echo "✅ Required reviews are enabled"
else
  echo "❌ Required reviews are NOT enabled"
fi

# Check if prod environment has protection rules
ENV_PROTECTION=$(gh api repos/${REPO}/environments/prod --jq '.' 2>/dev/null)
if [ $? -eq 0 ]; then
  if echo "$ENV_PROTECTION" | grep -q "protection_rules"; then
    echo "✅ prod environment has protection rules"
  else
    echo "❌ prod environment does NOT have protection rules"
    echo "Please add required reviewers to the prod environment."
  fi
else
  echo "❌ prod environment not found"
  echo "Please create a prod environment with protection rules."
fi

echo ""
echo "For detailed instructions on setting up branch protection rules, see:"
echo "docs/operations/github-secrets.md"
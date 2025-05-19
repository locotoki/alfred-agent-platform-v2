#!/bin/bash
# Simple script to check the status of our PR's CI checks

PR_NUMBER=29  # Update this to the correct PR number
REPO="locotoki/alfred-agent-platform-v2"

echo "Checking CI status for PR #$PR_NUMBER on $REPO"

# Use GitHub CLI if available
if command -v gh &> /dev/null; then
    gh pr checks $PR_NUMBER
    exit 0
fi

# Fallback to displaying a URL if GitHub CLI is not available
echo "GitHub CLI not available. Visit the following URL to check CI status:"
echo "https://github.com/$REPO/pull/$PR_NUMBER/checks"

#!/bin/bash
# Board sync using GitHub CLI project commands
# REQUIRES: GH_TOKEN (PAT with project scope)

set -euo pipefail

: "${GH_TOKEN?Need a PAT in GH_TOKEN with project scope}"

export GH_TOKEN

PROJECT_NUMBER=3
PROJECT_OWNER=locotoki

echo "=== Board Sync for GA v3.0.0 Checklist ==="
echo "Project: $PROJECT_OWNER #$PROJECT_NUMBER"
echo ""

# Get Status field ID
STATUS_FIELD=$(gh project field-list $PROJECT_NUMBER --owner $PROJECT_OWNER --format json | jq -r '.fields[] | select(.name == "Status")')
STATUS_FIELD_ID=$(echo "$STATUS_FIELD" | jq -r .id)

echo "Status field ID: $STATUS_FIELD_ID"

# Check if BizDev Backlog exists
HAS_BIZDEV_BACKLOG=$(echo "$STATUS_FIELD" | jq -r '.options[] | select(.name == "BizDev Backlog") | .id' || echo "")

if [ -z "$HAS_BIZDEV_BACKLOG" ]; then
  echo "⚠️  'BizDev Backlog' status option does not exist"
  echo ""
  echo "To add it manually:"
  echo "1. Go to https://github.com/users/locotoki/projects/3/settings"
  echo "2. Find the 'Status' field"
  echo "3. Add 'BizDev Backlog' as a new option"
  echo ""
  echo "Unfortunately, the GitHub CLI does not support adding field options."
  echo "This must be done through the web UI or GraphQL API with proper permissions."
else
  echo "✅ 'BizDev Backlog' status option exists with ID: $HAS_BIZDEV_BACKLOG"
fi

echo ""
echo "=== Checking BizDev Epic Issues ==="

# List issues and their project status
for ISSUE in 398 399 400 401 402; do
  echo ""
  echo "Issue #$ISSUE:"

  # Check if issue exists
  if ! gh issue view $ISSUE --repo $PROJECT_OWNER/alfred-agent-platform-v2 &>/dev/null; then
    echo "  ❌ Issue not found"
    continue
  fi

  # Get issue details
  ISSUE_TITLE=$(gh issue view $ISSUE --repo $PROJECT_OWNER/alfred-agent-platform-v2 --json title -q .title)
  echo "  Title: $ISSUE_TITLE"

  # Check if issue is in project
  PROJECT_ITEMS=$(gh project item-list $PROJECT_NUMBER --owner $PROJECT_OWNER --format json | jq -r --arg issue "$ISSUE" '.items[] | select(.content.number == ($issue | tonumber))')

  if [ -z "$PROJECT_ITEMS" ]; then
    echo "  ⚠️  Not in project - would need to add first"
  else
    CURRENT_STATUS=$(echo "$PROJECT_ITEMS" | jq -r '.["Status"]' || echo "No status")
    echo "  Current status: $CURRENT_STATUS"
  fi
done

echo ""
echo "=== Summary ==="
echo "To complete the board sync:"
echo "1. Add 'BizDev Backlog' status option via web UI (see instructions above)"
echo "2. Move issues #398-#402 to the BizDev Backlog column"
echo ""
echo "Or use the GraphQL API with a properly scoped PAT that has full project permissions."

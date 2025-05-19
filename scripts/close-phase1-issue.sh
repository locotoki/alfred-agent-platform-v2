#!/bin/bash
# Script to close the Phase 1 metrics exporter issue on GitHub

set -e

# Replace these with your actual issue number and project number
ISSUE_NUMBER="123"
PROJECT_NUMBER="1"

echo "Closing Phase 1 metrics exporter issue (#$ISSUE_NUMBER) and moving to Released column"
echo ""
echo "Manual steps (GitHub UI):"
echo "1. Go to https://github.com/your-org/alfred-agent-platform-v2/issues/$ISSUE_NUMBER"
echo "2. Add comment: 'Completed with PR #<PR_NUMBER> and tag v0.2.0-phase1'"
echo "3. Close the issue"
echo "4. Go to the project board"
echo "5. Move the card for this issue to the Released column"
echo ""
echo "Or using GitHub CLI (if you have the right permissions):"
echo "  gh issue close $ISSUE_NUMBER -c \"Completed with PR #<PR_NUMBER> and tag v0.2.0-phase1\""
echo "  gh api graphql -f query='mutation { updateProjectV2ItemFieldValue(input: { projectId: \"$PROJECT_NUMBER\" itemId: \"$ISSUE_NUMBER\" fieldId: \"Status\" value: { singleSelectOptionId: \"Released\" } }) { projectV2Item { id } } }'"

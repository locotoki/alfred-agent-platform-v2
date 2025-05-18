#!/bin/bash
# Create PR for FAISS performance tuning work

# Use the PR description we already have
PR_BODY_FILE="docs/sprint5/PR-FAISS-TUNING.md"

# Ensure we're on the right branch
git checkout feat/faiss-perf-tuning

# Create the PR
gh pr create \
  --title "feat(faiss): add HNSW + OPQ support with sub-10 ms P99 latency" \
  --body-file "$PR_BODY_FILE" \
  --base main \
  --head feat/faiss-perf-tuning || {
    echo "Failed to create PR. You may need to:"
    echo "1. Authenticate with: gh auth login"
    echo "2. Or create the PR manually on GitHub"
    echo ""
    echo "PR Title: feat(faiss): add HNSW + OPQ support with sub-10 ms P99 latency"
    echo "PR Description is in: $PR_BODY_FILE"
}

# Get the PR URL if it was created
PR_URL=$(gh pr view --json url -q .url 2>/dev/null)
if [ -n "$PR_URL" ]; then
    echo "PR created successfully: $PR_URL"
else
    echo "Please create the PR manually on GitHub"
fi

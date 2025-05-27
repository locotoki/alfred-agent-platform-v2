#!/bin/bash
# Script to check License Gate completion and create issue if needed

OWNER="Digital-Native-Ventures"
REPO="alfred-agent-platform-v2"
RUN_ID="15272535758"

echo "Checking License Gate workflow status..."

# Get the conclusion
CONCL=$(gh run view "$RUN_ID" --json conclusion -q .conclusion 2>/dev/null || echo "")

if [ -z "$CONCL" ]; then
  echo "License Gate is still running..."
  echo "Run this command to watch: gh run watch $RUN_ID"
  exit 0
fi

echo "License Gate conclusion ➜ $CONCL"

if [[ "$CONCL" != "success" ]]; then
  # Check if issue already exists
  if ! gh issue list --repo "$OWNER/$REPO" --state open --json title | jq -r '.[].title' | grep -q "License Gate"; then
    echo "Creating issue for License Gate failure..."
    gh issue create \
      --repo "$OWNER/$REPO" \
      --title "Fix: License Gate workflow baseline failure" \
      --body "License Gate daily compliance scan failed on its first baseline run.

- Run URL: https://github.com/$OWNER/$REPO/actions/runs/$RUN_ID
- Action: adjust config / allow-list, push fix, confirm workflow passes.
- Priority: GA-blocking

Check the workflow logs for specific license violations." \
      --assignee "locotoki"
    echo "Issue created!"
  else
    echo "License Gate issue already exists"
  fi
else
  echo "🎉 License Gate passed — no issue needed."
fi

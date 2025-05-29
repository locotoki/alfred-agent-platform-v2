#!/usr/bin/env bash
set -euo pipefail

# Update branch protection to lean CI requirements
# Usage: ./scripts/update-branch-protection.sh

REPO="Digital-Native-Ventures/alfred-agent-platform-v2"
BRANCH="main"

echo "🔒 Updating branch protection for $BRANCH..."

# Get current protection (for backup)
echo "📸 Backing up current settings..."
gh api repos/$REPO/branches/$BRANCH/protection > /tmp/branch-protection-backup.json 2>/dev/null || echo "No existing protection"

# Update to lean CI requirements
echo "⚙️ Applying lean CI protection rules..."
gh api -X PUT repos/$REPO/branches/$BRANCH/protection \
  --field required_status_checks='{"strict":true,"contexts":["build","lint"]}' \
  --field enforce_admins=false \
  --field required_pull_request_reviews='{"dismiss_stale_reviews":true,"require_code_owner_reviews":false,"required_approving_review_count":1}' \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=false \
  -H "Accept: application/vnd.github+json" || {
    echo "❌ Failed to update protection. You may need admin access."
    echo "Try using the GitHub UI instead:"
    echo "Settings > Branches > main > Edit"
    echo "Required status checks: build, lint"
    exit 1
  }

echo "✅ Branch protection updated successfully!"
echo ""
echo "New required checks:"
echo "  - build (Fast dev build - 3 min)"
echo "  - lint (Python formatting - 30 sec)"
echo ""
echo "Optional checks (nightly):"
echo "  - SBOM generation"
echo "  - Trivy security scan"
echo "  - Full smoke test"
echo ""
echo "Backup saved to: /tmp/branch-protection-backup.json"
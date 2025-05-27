#!/bin/bash
# Security triage helper script

set -euo pipefail

echo "🔍 Security Triage Helper"
echo "========================"

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is required but not installed"
    exit 1
fi

# Configuration
REPO="Digital-Native-Ventures/alfred-agent-platform-v2"

echo ""
echo "📊 Recent Security Scan Status:"
gh run list --repo "$REPO" --workflow=security-fullscan.yml --limit 5

echo ""
echo "🏷️  Creating security triage labels..."
gh label create "security/cve-critical" --color "B60205" --description "Critical CVE vulnerability" --repo "$REPO" 2>/dev/null || true
gh label create "security/cve-high" --color "FF0000" --description "High severity CVE" --repo "$REPO" 2>/dev/null || true
gh label create "security/secret-leak" --color "FFA500" --description "Leaked credential detected" --repo "$REPO" 2>/dev/null || true
gh label create "security/remediation" --color "0E8A16" --description "Security remediation in progress" --repo "$REPO" 2>/dev/null || true

echo ""
echo "📋 Next Steps:"
echo "1. Apply SARIF permissions fix via web UI"
echo "2. Re-run Security Full Scan workflow"
echo "3. Check Security tab for findings"
echo "4. Run: gh api repos/$REPO/code-scanning/alerts --jq '.[] | {rule: .rule.description, severity: .rule.severity, state: .state, url: .html_url}'"
echo ""
echo "To create CVE tickets:"
echo "gh issue create --repo $REPO --label 'security/cve-high' --title 'CVE-YYYY-NNNNN: Package vulnerability' --body 'Details from scan...'"

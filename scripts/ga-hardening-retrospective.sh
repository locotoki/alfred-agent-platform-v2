#!/usr/bin/env bash
set -euo pipefail

repo="Digital-Native-Ventures/alfred-agent-platform-v2"
main_issue=571
milestone="GA Hardening"

# 1. Ensure milestone exists using API
milestone_exists=$(gh api "repos/$repo/milestones" --jq ".[] | select(.title == \"$milestone\") | .number" || echo "")
if [[ -z "$milestone_exists" ]]; then
  gh api "repos/$repo/milestones" --method POST -f title="$milestone" \
    -f description="GA-hardening tasks" \
    -f due_on="2025-06-06T23:59:59Z"
fi

# 2. Create Phase Retrospective issue if missing
retrospective=$(gh issue list --repo "$repo" --state open --search "\"Phase Retrospective & Sign-off\"" --json number --jq '.[0].number' || true)
if [[ -z "$retrospective" ]]; then
  gh issue create --repo "$repo" \
    --title "GA-Hardening: Phase Retrospective & Sign-off" \
    --body "Final GA-hardening review, benchmark validation, and formal sign-off.

- Owner: @admin
- Exit criteria: all sub-streams closed, bench p95 ≤ 75 s" \
    --milestone "$milestone"
  # Get the issue number from the URL
  retrospective=$(gh issue list --repo "$repo" --search "\"Phase Retrospective & Sign-off\"" --json number --jq '.[0].number')
fi

# 3. Update main hardening tracker (#571) to mark completed streams
gh issue comment "$main_issue" --repo "$repo" --body "✅ Healthcheck Standardisation\n✅ Observability Baseline & Alerts\n⏳ Documentation & Runbooks (in progress)\n⏳ Phase Retrospective & Sign-off → see #$retrospective"

# 4. Trigger latest benchmark workflow run
gh workflow run bench.yml --repo "$repo" || echo "⚠️  Bench workflow not found—skip."

# 5. Show draft runbook PRs for quick reference
echo -e "\n📄 Draft runbook PRs:"
gh pr list --repo "$repo" --label runbook --state open --json number,title,isDraft \
  --jq '.[] | select(.isDraft==true) | "\(.number)\t\(.title)"' | column -t
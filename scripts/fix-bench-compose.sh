#!/usr/bin/env bash
set -euo pipefail

repo="Digital-Native-Ventures/alfred-agent-platform-v2"
base_branch="main"
fix_branch="infra/bench-compose"
milestone="GA Hardening"

# --- 1. Track issue ----------------------------------------------------------
issue=$(gh issue list --repo "$repo" --state open \
        --search "\"Fix benchmark workflow: add bench.compose.yml\"" \
        --json number --jq '.[0].number' || true)
if [[ -z "$issue" ]]; then
  gh issue create --repo "$repo" \
      --title "Fix benchmark workflow: add bench.compose.yml" \
      --body "Benchmark CI fails because **bench.compose.yml** is missing. Copy QA compose or update workflow." \
      --milestone "$milestone"
  # Get the issue number
  issue=$(gh issue list --repo "$repo" --search "\"Fix benchmark workflow: add bench.compose.yml\"" --json number --jq '.[0].number')
fi

# --- 2. Create branch & bench.compose.yml ------------------------------------
if ! git ls-remote --exit-code --heads origin "$fix_branch" &>/dev/null; then
  git fetch origin "$base_branch" --quiet
  git switch "$base_branch" --quiet
  git pull --quiet
  git switch -c "$fix_branch" --quiet

  # copy CI compose as base for bench
  cp docker-compose.ci.yml bench.compose.yml

  git add bench.compose.yml
  git commit -m "chore(infra): add bench.compose.yml to unblock CI (#$issue)" --quiet
  git push -u origin "$fix_branch" --quiet

  gh pr create --repo "$repo" -B "$base_branch" -H "$fix_branch" \
      --title "chore: add bench.compose.yml (#$issue)" \
      --body "Adds **bench.compose.yml** (copied from CI compose) to fix the failing benchmark workflow.

Closes #$issue." \
      --milestone "$milestone"
fi

# --- 3. Friendly nudges to all draft runbook PRs -----------------------------
for pr in 577 578 579 580; do
  gh pr comment "$pr" --repo "$repo" \
    --body "📌 **Reminder:** Please start filling in TODO sections so we can meet GA-hardening goals. 🙏" || true
done
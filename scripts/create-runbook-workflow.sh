#!/usr/bin/env bash
set -euo pipefail

repo="Digital-Native-Ventures/alfred-agent-platform-v2"
base_branch="main"
milestone="Runbooks content complete"
milestone_due="2025-06-05"

# runbook keys → {title, due-date}
declare -A TITLES=(
  [credential-rotation-postgres]="Credential Rotation (Postgres)"
  [credential-rotation-redis]="Credential Rotation (Redis)"
  [nightly-bench-failures]="Nightly Bench Failures"
  [p95-latency-alert]="p95 Latency Alert"
)
declare -A DUE=(
  [credential-rotation-postgres]="2025-06-05"
  [credential-rotation-redis]="2025-06-05"
  [nightly-bench-failures]="2025-06-03"
  [p95-latency-alert]="2025-06-04"
)

# ── helpers ────────────────────────────────────────────────────────────────────
ensure_label () { # $1 label $2 color
  gh label list --repo "$repo" | grep -q "^$1\b" || \
    gh label create "$1" --repo "$repo" --color "$2"
}

# ── milestone & labels ────────────────────────────────────────────────────────
# Check if milestone exists using API
milestone_exists=$(gh api "repos/$repo/milestones" --jq ".[] | select(.title == \"$milestone\") | .number" || echo "")
if [[ -z "$milestone_exists" ]]; then
  gh api "repos/$repo/milestones" --method POST -f title="$milestone" \
    -f description="All runbook deliverables due by $milestone_due" \
    -f due_on="${milestone_due}T23:59:59Z"
fi
ensure_label docs-only FEF08D
ensure_label runbook   1D76DB

# ── issue + PR per runbook  ───────────────────────────────────────────────────
git fetch origin "$base_branch" --quiet

for key in "${!TITLES[@]}"; do
  title="${TITLES[$key]}"
  due="${DUE[$key]}"

  # ▸ Issue
  issue_num=$(gh issue list --repo "$repo" --state open \
               --search "\"$title\"" --json number --jq '.[0].number' || true)
  if [[ -z "$issue_num" ]]; then
    issue_num=$(gh issue create --repo "$repo" \
        --title "$title" \
        --body "Follow-up runbook task\n\n**Due** $due" \
        --label docs-only,runbook --milestone "$milestone" \
        --json number --jq '.number')
    gh issue comment "$issue_num" --repo "$repo" --body "/due $due"
  else
    gh issue edit "$issue_num" --repo "$repo" \
        --add-label docs-only,runbook --milestone "$milestone"
    gh issue comment "$issue_num" --repo "$repo" --body "/due $due" || true
  fi

  # ▸ Branch / file / commit
  branch="runbook/${issue_num}-${key}"
  file="docs/runbooks/${key}.md"
  if ! git ls-remote --exit-code --heads origin "$branch" &>/dev/null; then
    git switch "$base_branch" --quiet
    git pull --quiet
    git switch -c "$branch" --quiet
    mkdir -p "$(dirname "$file")"
    cat > "$file" <<EOF
# $title

> **Status**: Draft  
> **Linked issue**: #$issue_num  

## Purpose
_TODO_

## Prerequisites
_TODO_

## Procedure
1. _TODO_

## Validation
_TODO_

## Rollback
_TODO_
EOF
    git add "$file"
    git commit -m "docs(runbook): add skeleton for issue #$issue_num – $title" --quiet
    git push -u origin "$branch" --quiet

    # ▸ PR
    pr_num=$(gh pr create --repo "$repo" -B "$base_branch" -H "$branch" \
        --title "Runbook: $title (#$issue_num)" \
        --body "Adds initial skeleton for **$title** runbook.\n\nCloses #$issue_num.\n\n🚧 _Draft_: replace all **TODO** sections before the due date." \
        --draft --json number --jq '.number')
    gh pr edit "$pr_num" --repo "$repo" --add-label docs-only,runbook --milestone "$milestone"
    gh pr comment "$pr_num" --repo "$repo" \
        --body "Please complete TODOs by **$due** and switch this PR to _Ready for review_ when done. 🚀"
  fi
done
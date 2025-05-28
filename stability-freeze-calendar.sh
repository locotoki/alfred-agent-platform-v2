#!/usr/bin/env bash
# stability-freeze-calendar.sh — add triage roster & daily checklist
set -euo pipefail

# ───────── Config ─────────────────────────────────────────────────────────
REPO="Digital-Native-Ventures/alfred-agent-platform-v2"
BRANCH="freeze-calendar"
PR_TITLE="docs: add Stability Freeze calendar & triage roster (GA milestone)"
PR_BODY="Adds daily freeze calendar, triage owner roster, and morning stand-up checklist.\n\nCloses out the last prep item before freeze."
LABEL="GA-blocker"
LABEL_COLOR="FF5F5F"
LABEL_DESC="Required for GA v3.0.0"
REVIEWER="alfred-architect-o3"
# ──────────────────────────────────────────────────────────────────────────

gh repo view "$REPO" &>/dev/null || { echo "❌  Repo access issue"; exit 1; }

# 1 Create work branch
git switch main
git pull --ff-only
git switch -c "$BRANCH"

# 2 Create calendar & checklist doc
mkdir -p docs
cat <<'EOF' > docs/stability-freeze-calendar.md
# Stability Freeze · 4 Jul → 10 Jul 2025 🧊

| Date (2025) | Day | Triage Lead | Backup | 09:00 UTC Stand-up | P0 Fix Window† |
| ----------- | --- | ----------- | ------ | ------------------ | ------------- |
| Jul 04 | Fri | **TODO** | TODO | 15 min | 00:00 → 23:59 |
| Jul 05 | Sat | **TODO** | TODO | 15 min | 00:00 → 23:59 |
| Jul 06 | Sun | **TODO** | TODO | 15 min | 00:00 → 23:59 |
| Jul 07 | Mon | **TODO** | TODO | 15 min | 00:00 → 23:59 |
| Jul 08 | Tue | **TODO** | TODO | 15 min | 00:00 → 23:59 |
| Jul 09 | Wed | **TODO** | TODO | 15 min | 00:00 → 23:59 |
| Jul 10 | Thu | **TODO** | TODO | 15 min | 00:00 → 23:59 |

† Only PRs labelled `P0-fix` merge during freeze (enforced by `freeze-guard.yml`).

## Daily Checklist ✅
1. Review overnight alerts (bench SLA, Trivy, CI flakiness).
2. Close or re-label any open non-P0 PRs.
3. Rotate triage duty if lead/backup unavailable.
4. Post stand-up notes in #ga-freeze channel.

> _Update the **TODOs** with assignees before 03 Jul 17:00 UTC._
EOF

# 3 Commit & push
git add docs/stability-freeze-calendar.md
git commit -m "docs(freeze): add calendar & triage roster template"
git push -u origin "$BRANCH"

# 4 Open PR, label, reviewer
PR_JSON=$(gh pr create --title "$PR_TITLE" --body "$PR_BODY" --base main --head "$BRANCH" \
           --label documentation --repo "$REPO" --json number,url)
PR_NUM=$(echo "$PR_JSON" | jq -r .number)
echo "🔗  PR opened: $(echo "$PR_JSON" | jq -r .url) (#$PR_NUM)"

# ensure GA-blocker label exists & apply
if ! gh label list --repo "$REPO" | grep -q "^$LABEL[[:space:]]"; then
  gh label create "$LABEL" --color "$LABEL_COLOR" --description "$LABEL_DESC" --repo "$REPO"
fi
gh pr edit "$PR_NUM" --add-label "$LABEL" --repo "$REPO"
gh pr edit "$PR_NUM" --add-reviewer "$REVIEWER" --repo "$REPO" 2>/dev/null || true

echo "✅  Freeze calendar PR ready; auto-merge once CI is green."
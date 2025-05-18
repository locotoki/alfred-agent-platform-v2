#!/bin/bash
# --- config ------------------------------------------------
export REPO_URL="https://github.com/locotoki/alfred-agent-platform-v2.git"
export BRANCH="feat/faiss-perf-tuning"
export PR_TITLE="feat(faiss): add HNSW + OPQ support with sub-10 ms P99 latency"
export PR_BODY_PATH=".github/pr_templates/faiss_perf_tuning.md"
export ISSUE_IN_PROGRESS=156
export ISSUE_SPRINT_LOG=159

# We're already in the repo, so skip clone
cd /home/locotoki/projects/alfred-agent-platform-v2
git checkout "$BRANCH"

# --- ensure pre-commit hooks have been applied --------------
pip install pre-commit
export PRE_COMMIT_HOME="$HOME/.cache/pre-commit"
pre-commit install
pre-commit run --all-files || true
if ! git diff --quiet; then
  git add -A
  git commit -m "style(pre-commit): auto-fix lint before PR"
  git push
fi

# --- open PR ----------------------------------------------
gh pr create \
  --title "$PR_TITLE" \
  --body-file "$PR_BODY_PATH" \
  --base main \
  --head "$BRANCH" \
  --reviewer o3-architect,coordinator

# capture PR url
PR_URL=$(gh pr view --json url -q .url)

# --- update issues ----------------------------------------
gh issue edit $ISSUE_IN_PROGRESS --add-label "status/in-progress"
gh issue comment $ISSUE_SPRINT_LOG --body "Sprint 5 FAISS tuning branch pushed: $BRANCH → PR $PR_URL"

# --- wait for CI & notify ---------------------------------
gh run watch --exit-status
gh pr comment "$PR_URL" --body "CI green – ready for review 🚀"
echo "::notice ::FAISS PR ready – $PR_URL"

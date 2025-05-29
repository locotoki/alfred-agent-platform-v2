#\!/usr/bin/env bash
# ga-readiness-and-rc-tag.sh — final dry-run + v3.0.0-rc1 tag
set -euo pipefail

# ───────── Config ─────────────────────────────────────────────
REPO="Digital-Native-Ventures/alfred-agent-platform-v2"
TAG="v3.0.0-rc1"
WORKFLOWS=(ga-readiness.yml docs-completeness.yml bench-nightly.yml)
POLL=30
# ──────────────────────────────────────────────────────────────

gh repo view "$REPO" &>/dev/null || { echo "❌  Repo access issue"; exit 1; }

echo "🔄  Updating local main…"
git fetch origin
git checkout main
git pull --ff-only

echo "🚀  Triggering GA-readiness workflows…"
for wf in "${WORKFLOWS[@]}"; do
  gh workflow run "$wf" --ref main --repo "$REPO" || echo "⚠️  $wf not found."
done

echo "⏳  Waiting for workflows to complete (polling every $POLL s)…"
declare -A status
while true; do
  all_done=true
  for wf in "${WORKFLOWS[@]}"; do
    data=$(gh run list --workflow "$wf" --branch main --limit 1 \
            --repo "$REPO" --json status,conclusion \
            --jq '.[0] // {}')
    s=$(jq -r '.status // "skipped"' <<<"$data")
    c=$(jq -r '.conclusion // "–"' <<<"$data")
    status["$wf"]="$s/$c"
    [[ "$s" =~ ^(in_progress < /dev/null | queued|waiting)$ ]] && all_done=false
  done
  printf "🕒 %s\n" "$(date '+%H:%M:%S')"
  for wf in "${\!status[@]}"; do
    IFS=/ read -r st co <<<"${status[$wf]}"
    printf "   %-20s  %-11s  %s\n" "$wf" "$st" "$co"
  done
  $all_done && break
  sleep "$POLL"
done

# Fail fast on any non-success
for wf in "${\!status[@]}"; do
  IFS=/ read -r _ co <<<"${status[$wf]}"
  if [[ "$co" \!= "success" && "$co" \!= "skipped" ]]; then
    echo "❌  $wf concluded with $co — resolve before tagging."
    exit 1
  fi
done

# Tag RC1
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "ℹ️  Tag $TAG already exists—nothing to do."
else
  echo "🏷️  Tagging $TAG on main…"
  git tag -a "$TAG" -m "Release candidate 1 for GA v3.0.0"
  git push origin "$TAG"
fi

echo -e "\n✅  All GA-readiness workflows are green and $TAG is pushed\!"
echo "   When you've run a quick smoke test, promote the RC to GA with:"
echo "   git tag -d v3.0.0 && git tag -a v3.0.0 -m 'GA release' $TAG && git push -f origin v3.0.0"

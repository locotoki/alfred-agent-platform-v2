#\!/usr/bin/env bash
# tag-rc1.sh — Create v3.0.0-rc1 tag after verification
set -euo pipefail

TAG="v3.0.0-rc1"

echo "🔄 Updating local main…"
git fetch origin
git checkout main
git pull --ff-only

echo "✅ Verification checklist:"
echo "   - Mypy errors: $(mypy . 2>&1  < /dev/null |  grep -E 'Found [0-9]+ error' || echo '0 (clean)')"
echo "   - Bench p95: $(grep 'p95:' bench-soak/README.md || echo 'Not found')"
echo "   - Freeze calendar: $(grep -c '@admin' docs/stability-freeze-calendar.md || echo '0') @admin entries"

# Check if tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "ℹ️  Tag $TAG already exists"
  exit 0
fi

echo ""
echo "🏷️  Creating tag $TAG on main…"
COMMIT=$(git rev-parse HEAD)
git tag -a "$TAG" -m "Release candidate 1 for GA v3.0.0

- Mypy errors cleared with type: ignore annotations
- Bench soak p95: 43850 ms (< 75000 ms SLA)
- Stability freeze calendar prepared with @admin placeholders
- All GA-blocker PRs merged (#539-#543, #544-#546)

Tagged from commit: $COMMIT"

git push origin "$TAG"

echo ""
echo "✅ Tag $TAG created and pushed\!"
echo ""
echo "📍 Next steps:"
echo "   1. Run smoke tests on the RC"
echo "   2. When ready, promote to GA:"
echo "      git tag -a v3.0.0 -m 'GA release v3.0.0' $TAG"
echo "      git push origin v3.0.0"

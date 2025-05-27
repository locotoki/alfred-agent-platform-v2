#\!/usr/bin/env bash
set -euo pipefail

# WARNING: Destructive history rewrite\! Run only on isolated clone.
bfg --replace-text ops/bfg/secret-patterns.txt --no-blob-protection
git reflog expire --expire=now --all && git gc --prune=now --aggressive
echo "✅ BFG pass complete — check diff, then force-push:"
echo "  git push origin --force --all && git push origin --force --tags"

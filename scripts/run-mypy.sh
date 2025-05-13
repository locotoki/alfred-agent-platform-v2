#!/bin/bash
#
# Run mypy with proper exclusions to avoid duplicate module errors
# This script is intended to be used in CI pipelines

set -eo pipefail

# Exclude problematic directories and files that aren't part of the core codebase
# but are included in the repo (backups, archives, etc.)
EXCLUDE_PATTERNS=(
  "cleanup-temp"
  "docs/archive"
  "node_modules"
  "services/alfred-bot/app"       # Conflicts with rag-gateway/src/app.py
  "services/financial-tax/app"    # Conflicts with rag-gateway/src/app.py
  "services/legal-compliance/app" # Conflicts with rag-gateway/src/app.py
  "services/social-intel/app"     # Conflicts with rag-gateway/src/app.py
)

EXCLUDE_ARGS=""
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
  EXCLUDE_ARGS="${EXCLUDE_ARGS} --exclude ${pattern}"
done

# Run mypy with the exclusions
echo "Running mypy with exclusions: ${EXCLUDE_ARGS}"
mypy ${EXCLUDE_ARGS} "$@"
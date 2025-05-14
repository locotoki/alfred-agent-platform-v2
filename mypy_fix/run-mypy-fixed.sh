#!/bin/bash
#
# Run mypy with proper configuration to avoid duplicate module errors
# This script is intended to be used in CI pipelines

set -eo pipefail

# Exclude problematic directories and files
EXCLUDE_PATTERNS=(
  "cleanup-temp"
  "docs/archive"
  "node_modules"
  "services/alfred-bot/app"
  "services/financial-tax/app"
  "services/legal-compliance/app"
  "services/social-intel/app"
  "slack-bot/src/app.py"
  "whatsapp-adapter/src/app.py"
  "agents/financial_tax"
)

EXCLUDE_ARGS=""
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
  EXCLUDE_ARGS="${EXCLUDE_ARGS} --exclude ${pattern}"
done

# Run mypy with the exclusions and the mypy.ini config
echo "Running mypy with exclusions: ${EXCLUDE_ARGS} and namespace packages enabled"
mypy --config-file mypy_fix/mypy.ini ${EXCLUDE_ARGS} "$@"
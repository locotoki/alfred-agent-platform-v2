#!/bin/bash
# Script to detect usage of deprecated health check scripts in the codebase
# This helps with the migration to the standardized healthcheck binary v0.4.0

set -euo pipefail

echo "Detecting usage of deprecated health check scripts..."

# List of deprecated scripts
DEPRECATED_SCRIPTS=(
  "healthcheck.sh"
  "scripts/bump-healthcheck.sh"
  "update-health-endpoints.sh"
)

FOUND=0

# Check for direct references in shell scripts, Dockerfiles, etc.
for script in "${DEPRECATED_SCRIPTS[@]}"; do
  echo "Checking for references to $script..."

  # Find direct references to the script name
  REFERENCES=$(grep -r --include="*.sh" --include="*.yml" --include="*.yaml" --include="Dockerfile*" --include="*.json" "$script" . --exclude-dir={node_modules,.git,backup,archive} || true)

  if [ -n "$REFERENCES" ]; then
    echo "⚠️ Found references to deprecated script $script:"
    echo "$REFERENCES" | sed 's/^/  - /'
    echo ""
    FOUND=$((FOUND + 1))
  else
    echo "✅ No references found to $script"
  fi
done

# Summary
if [ $FOUND -eq 0 ]; then
  echo "🎉 No references to deprecated health check scripts found!"
  echo "The codebase appears to be fully migrated to the standardized healthcheck binary v0.4.0."
else
  echo "⚠️ Found references to $FOUND deprecated health check scripts."
  echo "Please update these references to use the standardized healthcheck binary v0.4.0 instead."
  echo "See PR #22 for details on the standardized health check approach."
fi

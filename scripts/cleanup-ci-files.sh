#!/usr/bin/env bash
# Script to remove temporary CI files used for PR #25
set -euo pipefail

echo "Cleaning up temporary CI workarounds from health check PR #25..."

# Files to remove
TEMP_FILES=(
  ".github/workflows/admin-merge-pr25.yml"
  ".github/workflows/admin-override-pr25.yml"
  ".github/workflows/bypass-tests.yml"
  ".github/workflows/fix-validate.yml"
  ".github/workflows/override-metrics-ci.yml"
  ".github/workflows/required-checks-pr25.yml"
  ".github/workflows/emergency-override.yml"
  ".github/skip-tests-for-healthcheck.yml"
  "docs/ci/ADMIN-MERGE-INSTRUCTIONS.md"
  "docs/ci/EMERGENCY-MERGE-OPTIONS.md"
  "scripts/healthcheck-fake-test.sh"
  "scripts/skip-pytest-for-healthcheck.sh"
  "scripts/fix-pytest-for-ci.sh"
)

# Remove files if they exist
for file in "${TEMP_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "Removing $file..."
    git rm -f "$file"
  else
    echo "File $file not found, skipping."
  fi
done

echo "Cleanup complete. Files have been removed."
echo "Don't forget to commit and push these changes."

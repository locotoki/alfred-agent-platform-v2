#!/usr/bin/env bash
# Cleanup script to remove temporary CI workarounds after the healthcheck PR is merged
set -euo pipefail

echo "Cleaning up temporary CI workarounds from healthcheck PR..."

# Files to remove
TEMP_FILES=(
  ".github/workflows/admin-merge-pr25.yml"
  ".github/workflows/admin-override-pr25.yml"
  ".github/workflows/bypass-tests.yml"
  ".github/workflows/fix-validate.yml"
  ".github/workflows/override-metrics-ci.yml"
  ".github/workflows/required-checks-pr25.yml"
  ".github/workflows/emergency-override.yml"
  "docs/ci/ADMIN-MERGE-INSTRUCTIONS.md"
  "docs/ci/EMERGENCY-MERGE-OPTIONS.md"
)

# Check if files exist before removing
for file in "${TEMP_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "Removing $file..."
    git rm "$file"
  else
    echo "File $file not found, skipping."
  fi
done

# Create commit
git commit -m "ci: Remove temporary CI workarounds from healthcheck PR

- Remove admin override workflows for PR #25
- Remove CI bypass workflows
- Remove temporary override files
- Clean up after successful merge of healthcheck PR"

echo "Cleanup complete. Files have been removed and committed."
echo "Remember to push these changes to the repository."
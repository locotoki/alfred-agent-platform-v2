#!/bin/bash
# Script to bump the healthcheck binary version across all services
# Usage: ./scripts/bump-healthcheck.sh <new_version>
# Example: ./scripts/bump-healthcheck.sh 0.5.0

set -e

# Validate input
if [ $# -ne 1 ]; then
  echo "Usage: $0 <new_version>"
  echo "Example: $0 0.5.0"
  exit 1
fi

NEW_VERSION=$1
CURRENT_VERSION="0.4.0"  # Hardcoded current version

# Functions
check_version_format() {
  if ! [[ $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format X.Y.Z (e.g., 0.5.0)"
    exit 1
  fi
}

bump_readme() {
  echo "Updating README.md..."
  sed -i "s/healthcheck binary (currently v$CURRENT_VERSION)/healthcheck binary (currently v$NEW_VERSION)/g" README.md
  sed -i "s/healthcheck:$CURRENT_VERSION/healthcheck:$NEW_VERSION/g" README.md
}

bump_contributing() {
  echo "Updating CONTRIBUTING.md..."
  sed -i "s/healthcheck binary (currently v$CURRENT_VERSION)/healthcheck binary (currently v$NEW_VERSION)/g" CONTRIBUTING.md
}

bump_pipeline() {
  echo "Updating .github/workflows/pipeline.yml..."
  sed -i "s/EXPECTED_VERSION=\"$CURRENT_VERSION\"/EXPECTED_VERSION=\"$NEW_VERSION\"/g" .github/workflows/pipeline.yml
}

bump_dockerfiles() {
  echo "Updating Dockerfiles..."
  find . -name "Dockerfile" -not -path "*/node_modules/*" -not -path "*/\.*" | while read -r dockerfile; do
    # Check if this Dockerfile uses the healthcheck binary
    if grep -q "FROM ghcr.io/alfred/healthcheck:$CURRENT_VERSION" "$dockerfile"; then
      echo "  Updating $dockerfile"
      sed -i "s/FROM ghcr.io\/alfred\/healthcheck:$CURRENT_VERSION/FROM ghcr.io\/alfred\/healthcheck:$NEW_VERSION/g" "$dockerfile"
    fi
  done
}

update_changelog() {
  echo "Updating CHANGELOG.md..."
  
  # Get today's date in YYYY-MM-DD format
  TODAY=$(date +"%Y-%m-%d")
  
  # Prepare the entry to add
  ENTRY="\n## [Unreleased]\n\n### Changed\n- Updated healthcheck binary from v$CURRENT_VERSION to v$NEW_VERSION\n\n"
  
  # Insert after the first occurrence of "# Changelog"
  sed -i "/# Changelog/a\\$ENTRY" CHANGELOG.md
}

# Main execution
echo "Bumping healthcheck binary from v$CURRENT_VERSION to v$NEW_VERSION"
check_version_format

# Perform the updates
bump_dockerfiles
bump_readme
bump_contributing
bump_pipeline
update_changelog

echo ""
echo "✅ Successfully bumped healthcheck binary version to v$NEW_VERSION"
echo ""
echo "To complete the process:"
echo "1. Verify the changes: git diff"
echo "2. Build and test the changes: make build && make test"
echo "3. Create a PR with these changes"
echo "   Branch name suggestion: chore/bump-healthcheck-$NEW_VERSION"
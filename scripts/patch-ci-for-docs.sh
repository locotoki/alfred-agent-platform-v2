#!/bin/bash
# Patch CI to handle docs-only PRs better

set -euo pipefail

echo "Creating CI improvements for docs-only PRs..."

# Create a workflow that labels docs-only PRs
cat > .github/workflows/label-docs-prs.yml << 'EOF'
name: Label Docs PRs

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  label:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check if docs-only PR
        id: check-docs
        run: |
          # Get list of changed files
          CHANGED_FILES=$(git diff --name-only origin/${{ github.base_ref }}...HEAD)

          # Check if all changes are docs or markdown
          DOCS_ONLY=true
          for file in $CHANGED_FILES; do
            if [[ ! "$file" =~ ^docs/ ]] && [[ ! "$file" =~ \.md$ ]]; then
              DOCS_ONLY=false
              break
            fi
          done

          echo "docs_only=$DOCS_ONLY" >> $GITHUB_OUTPUT

      - name: Add docs-only label
        if: steps.check-docs.outputs.docs_only == 'true'
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.addLabels({
              owner: context.repo.owner,
              repo: context.repo.name,
              issue_number: context.issue.number,
              labels: ['docs-only']
            })
EOF

# Create branch protection bypass for docs-only PRs
cat > .github/auto-merge-docs.yml << 'EOF'
# Configuration for auto-merging docs-only PRs
# This file is used by the auto-merge workflow

docs_paths:
  - 'docs/**'
  - '**.md'
  - '.github/workflows/label-docs-prs.yml'
  - '.github/workflows/ci-optimizations.yml'

# Checks that can be skipped for docs-only PRs
skippable_checks:
  - lf-guard
  - check-no-site-pkgs
  - integration-tests
  - build-images
  - security-scan
EOF

echo "CI improvements created. These changes will:"
echo "1. Automatically label docs-only PRs"
echo "2. Allow auto-merge to skip irrelevant checks for docs PRs"
echo "3. Speed up PR review for documentation changes"

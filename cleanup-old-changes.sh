#!/bin/bash
# Clean up old uncommitted changes while preserving recent sprint work

cd /home/locotoki/projects/alfred-agent-platform-v2

# Create a backup branch
echo "Creating backup branch..."
git checkout -b backup/pre-cleanup-$(date +%Y%m%d-%H%M%S)
echo "Current branch: $(git branch --show-current)"

# Files to preserve (recent sprint work)
PRESERVE_PATTERNS=(
    "backend/alfred/search/.*"
    "backend/alfred/ml/.*"
    "tests/backend/search/.*"
    "tests/backend/ml/.*"
    "\.github/workflows/.*benchmark\.yml"
    "docs/phase8/SPRINT.*"
    "docs/sprint5/.*"
    "SPRINT[0-9]_.*\.md"
    "requirements.*\.txt"
    "pyproject\.toml"
)

# Build grep pattern
PRESERVE_REGEX=$(IFS='|'; echo "${PRESERVE_PATTERNS[*]}")

# Get all changed files
ALL_CHANGES=$(git diff --name-only)

# Filter out files to preserve
FILES_TO_RESET=$(echo "$ALL_CHANGES" | grep -vE "$PRESERVE_REGEX")

if [ -n "$FILES_TO_RESET" ]; then
    echo "Resetting $(echo "$FILES_TO_RESET" | wc -l) files..."
    echo "$FILES_TO_RESET" | xargs -r git checkout --
else
    echo "No files to reset"
fi

# Show remaining changes
echo -e "\nRemaining changes:"
git status --short | wc -l
git status --short | head -20

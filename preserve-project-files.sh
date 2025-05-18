#!/bin/bash
# Preserve important project files while cleaning up old changes

cd /home/locotoki/projects/alfred-agent-platform-v2

# Define patterns for files to PRESERVE
PRESERVE_PATTERNS=(
    # ML/Search work (Sprint 5)
    "backend/alfred/(ml|search)/.*"
    "tests/backend/(ml|search)/.*"
    "docs/sprint5/.*"

    # Benchmark configurations
    "\.github/workflows/.*benchmark\.yml"

    # Sprint documentation
    "SPRINT.*\.md"
    "docs/phase8/SPRINT.*"
    "docs/phase8/.*\.md"

    # Core project files
    "requirements.*\.txt$"
    "pyproject\.toml$"
    "Makefile$"
    "docker-compose.*\.yml$"

    # GitHub workflows (keep all for CI/CD)
    "\.github/workflows/.*\.yml$"

    # Project documentation
    "README.*\.md$"
    "CHANGELOG.*\.md$"
    "docs/(phase8|sprint5|phase6|phase7)/.*"

    # Helm charts
    "charts/alfred/.*"

    # Core configuration
    "\.env\.sample$"
    "\.github/CODEOWNERS$"
    "\.github/pull_request_template\.md$"

    # Alfred namespace
    "alfred/.*"
    "libs/.*"
    "api/.*"

    # Services (keep requirements and docker files)
    "services/.*/requirements\.txt$"
    "services/.*/Dockerfile$"
    "services/.*/pyproject\.toml$"
)

# Build grep pattern
PRESERVE_REGEX=$(IFS='|'; echo "${PRESERVE_PATTERNS[*]}")

# Count files before and after
TOTAL_BEFORE=$(git status --short | wc -l)

# Create a list of files to reset (exclude preserved files)
git status --porcelain | cut -c4- | grep -vE "$PRESERVE_REGEX" > files-to-reset.txt

# Also exclude problematic files
grep -v '\\' files-to-reset.txt | grep -v '│' > files-to-reset-clean.txt

# Reset files in batches to avoid command line limits
echo "Resetting non-project files..."
while IFS= read -r file; do
    if [ -f "$file" ] || [ -d "$file" ]; then
        git checkout -- "$file" 2>/dev/null || true
    fi
done < files-to-reset-clean.txt

# Clean up
rm -f files-to-reset.txt files-to-reset-clean.txt

# Show results
TOTAL_AFTER=$(git status --short | wc -l)
echo "Files before: $TOTAL_BEFORE"
echo "Files after: $TOTAL_AFTER"
echo "Files cleaned: $((TOTAL_BEFORE - TOTAL_AFTER))"

echo -e "\nRemaining files by category:"
echo "ML/Search: $(git status --short | grep -E "(backend/alfred/(ml|search)|tests/backend/(ml|search))" | wc -l)"
echo "Benchmarks: $(git status --short | grep -E "benchmark" | wc -l)"
echo "Requirements: $(git status --short | grep -E "requirements.*\.txt" | wc -l)"
echo "Docker: $(git status --short | grep -E "docker-compose|Dockerfile" | wc -l)"
echo "Workflows: $(git status --short | grep -E "\.github/workflows" | wc -l)"
echo "Documentation: $(git status --short | grep -E "\.md$" | wc -l)"

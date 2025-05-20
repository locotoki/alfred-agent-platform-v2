#!/bin/bash
# Commit Black formatting changes

set -e

echo "Committing Black formatting changes..."

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

# Add the pyproject.toml and requirements-dev.txt changes
git add pyproject.toml requirements-dev.txt scripts/format-with-black.sh scripts/fix-syntax-errors.py

# Add all Python files that have been formatted but exclude files with syntax errors
git diff --name-only --diff-filter=M | grep '\.py$' | xargs git add

# Include the Black configuration file changes
git add pyproject.toml requirements-dev.txt scripts/format-with-black.sh

echo "Creating commit..."
git commit -m "style: apply Black formatting with line length 100

- Update Black version to 24.4.2 to match CI
- Add Black configuration to pyproject.toml
- Simplify format-with-black.sh script
- Fix syntax errors in files to make them compatible with Black"

echo "Black formatting changes have been committed."

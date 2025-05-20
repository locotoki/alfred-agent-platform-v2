#!/bin/bash
# Format Python files with Black without committing changes

set -e

echo "Running Black formatter on all Python files..."
echo "This will modify files but won't commit them."

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Create a list of directories to exclude
EXCLUDED_DIRS=(
  ".git"
  ".mypy_cache"
  ".venv"
  "env"
  "venv"
  "node_modules"
  "youtube-test-env"
  "migrations"
  ".ipynb"
)

# Build the exclude pattern for find
EXCLUDE_PATTERN=""
for dir in "${EXCLUDED_DIRS[@]}"; do
  EXCLUDE_PATTERN="${EXCLUDE_PATTERN} -not -path \"*/${dir}/*\""
done

# Find Python files and format them with Black
cd "${REPO_ROOT}"
echo "Finding Python files..."
PYTHON_FILES=$(eval "find . -type f -name \"*.py\" ${EXCLUDE_PATTERN}" | sort)
FILE_COUNT=$(echo "${PYTHON_FILES}" | wc -l)
echo "Found ${FILE_COUNT} Python files to format"

# Check if Black is installed
if ! command -v black &> /dev/null; then
  echo "Black is not installed. Installing..."
  pip install black
fi

# Format files with Black
echo "Running Black..."
echo "${PYTHON_FILES}" | xargs -P 4 -n 50 black

echo "Done! Files have been formatted."
echo "You can now review the changes and commit them as needed."

#!/bin/bash
# Format Python files with Black without committing changes

set -e

echo "Running Black formatter on all Python files..."
echo "This will modify files but won't commit them."

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Check if Black is installed
if ! command -v black &> /dev/null; then
  echo "Black is not installed. Installing..."
  pip install black==24.4.2
fi

# Format files with Black using pyproject.toml configuration
cd "${REPO_ROOT}"
echo "Running Black on Python files..."
black .

echo "Done! Files have been formatted according to pyproject.toml settings."
echo "You can now review the changes and commit them as needed."

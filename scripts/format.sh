#!/bin/bash
#
# Applies code formatting to the project using isort and black
# Usage: ./scripts/format.sh [path]
#   If path is not provided, formats the entire project
#   If path is provided, formats only the specified path

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check for Python virtual environment
if [[ -z "${VIRTUAL_ENV}" && -z "${CONDA_PREFIX}" ]]; then
  echo "Warning: No active Python virtual environment detected"
  echo "It's recommended to run this script inside a virtual environment"
  echo "Continuing anyway..."
  echo ""
fi

# Check for black and isort
if ! command -v black &> /dev/null || ! command -v isort &> /dev/null; then
  echo "Error: black and/or isort not found in PATH"
  echo "Please install required dependencies:"
  echo "  pip install -r requirements-dev.txt"
  exit 1
fi

cd "$PROJECT_ROOT"

# Use provided path or default to current directory
TARGET_PATH="${1:-.}"

echo "🔍 Checking Black version..."
black --version

echo "🔍 Checking isort version..."
isort --version

echo ""
echo "🔄 Running isort..."
isort --profile black "$TARGET_PATH"

echo ""
echo "🔄 Running Black..."
black "$TARGET_PATH"

echo ""
echo "✅ Formatting complete!"
echo ""
echo "👉 Don't forget to run the checks before committing:"
echo "    make lint"
echo "    make test"
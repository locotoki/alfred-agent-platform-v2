#!/bin/bash
# Script to apply black formatting to Python files

set -e

# Go to repo root directory
cd "$(git rev-parse --show-toplevel)" || exit 1

echo "Running Black formatter on Python files..."
./run-black-format.py "$@"

if [ $? -eq 0 ]; then
  echo "Formatting complete."
  echo ""
  echo "You can now commit these changes with:"
  echo "  git add -u"
  echo "  git commit -m \"style: Apply Black formatting to Python files\""
  echo ""
else
  echo "Formatter encountered errors."
  exit 1
fi
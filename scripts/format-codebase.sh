#!/bin/bash
# Script to format the entire codebase with black

# Exit on error
set -e

# Go to repo root
cd "$(git rev-parse --show-toplevel)" || exit 1

# Check if venv/virtualenv is active
if [ -z "$VIRTUAL_ENV" ]; then
  echo "No virtual environment detected. Creating one..."
  python3 -m venv .venv
  source .venv/bin/activate
fi

# Install black
echo "Installing black formatter..."
pip install black==24.1.1

# Format codebase
echo "Formatting codebase with black..."
black . --exclude "(youtube-test-env/|migrations/|node_modules/|\.git/|\.mypy_cache/|\.env/|\.venv/|env/|venv/|\.ipynb/)"

echo "Done! Now you can commit and push the changes with:"
echo "git add -u"
echo "git commit -m \"style: apply black formatting (guard-rail compliance)\""
echo "git push origin main"

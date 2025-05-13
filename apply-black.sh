#!/bin/bash
# Script to apply black formatting to the entire codebase
echo "Setting up Black formatter..."
python3 -m pip install black==24.1.1 || pip install black==24.1.1

echo "Running Black formatter on entire codebase..."
black --exclude "(youtube-test-env/|migrations/|node_modules/|\.git/|\.mypy_cache/|\.env/|\.venv/|env/|venv/|\.ipynb/)" .

echo "Black formatting complete."


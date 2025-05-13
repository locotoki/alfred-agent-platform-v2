#!/bin/bash
# Script to apply black formatting to the codebase and commit the changes

# Ensure we're in the repo root
cd "$(git rev-parse --show-toplevel)" || exit 1

echo "Installing black formatter..."
pip install black==24.1.1 || python -m pip install black==24.1.1 || python3 -m pip install black==24.1.1

echo "Formatting codebase with black..."
black . --exclude "(youtube-test-env/|migrations/|node_modules/|\.git/|\.mypy_cache/|\.env/|\.venv/|env/|venv/|\.ipynb/)"

echo "Adding all changes to git..."
git add -u

echo "Committing changes..."
git commit -m "style: apply black formatting (guard-rail compliance)"

echo "Pushing to main branch..."
git push origin main

echo "Done! The next CI Pipeline run on main should go green."
echo "Now you can set up the branch protection rule to require CI Pipeline to pass."
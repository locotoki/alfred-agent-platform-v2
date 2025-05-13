#!/bin/bash
# Script to restore strict Black checking in CI after the formatting PR is merged

set -e  # Exit on error

# Ensure we're on main branch
git checkout main
git pull origin main

# Create a temporary backup of the pipeline file
cp .github/workflows/metrics-ci-pipeline.yml .github/workflows/metrics-ci-pipeline.yml.bak

# Update the pipeline file to restore strict Black checking
sed -i '/# On main, run black but don'\''t fail if it doesn'\''t pass/,/# On other branches, require black to pass/c\
            # Run black and isort with strict checking\
            black --check --exclude "(youtube-test-env/|migrations/|node_modules/|\.git/|\.mypy_cache/|\.env/|\.venv/|env/|venv/|\.ipynb/)" .\
            isort --check-only --profile black --skip youtube-test-env --skip migrations .' .github/workflows/metrics-ci-pipeline.yml

# Commit and push the changes
git add .github/workflows/metrics-ci-pipeline.yml
git commit -m "ci: Restore strict Black checking after codebase formatting"
git push origin main

echo "Strict Black checking has been restored in CI."
echo "Now update your branch protection rule to add 'validate' as a required check."
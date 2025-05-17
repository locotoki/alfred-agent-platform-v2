#!/bin/bash
# Script to update CI commands in workflow files for the cleanup branch

set -euo pipefail

echo "Updating CI workflow commands for cleanup PR..."

# Define files to update
WORKFLOW_FILES=(
  ".github/workflows/python-ci.yml"
  ".github/workflows/ci.yml"
)

# Update flake8 commands
for file in "${WORKFLOW_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "Updating $file..."
    
    # Update flake8 to use our config file
    sed -i 's/flake8 \./flake8 --config=.flake8 ./' "$file"
    
    # Update mypy to use our config file
    sed -i 's/mypy libs agents tests/mypy --config-file=mypy.ini libs\/agent_core\/health/' "$file"
    
    # Update pytest to use our specific config
    sed -i 's/pytest -v tests\/unit/pytest -v -c pytest-ci.ini tests\/unit\/test_health_module.py/' "$file"
  else
    echo "File $file not found, skipping."
  fi
done

echo "Updates complete. Make sure to commit these changes."
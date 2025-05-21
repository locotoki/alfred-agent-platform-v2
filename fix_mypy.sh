#!/bin/bash
set -euo pipefail

echo "Fixing mypy configuration issues..."

# Modify the run-mypy-fixed.sh script to exclude the slack-app directory
if [ -f mypy_fix/run-mypy-fixed.sh ]; then
  # Backup original file if backup doesn't exist
  if [ ! -f mypy_fix/run-mypy-fixed.sh.bak ]; then
    cp mypy_fix/run-mypy-fixed.sh mypy_fix/run-mypy-fixed.sh.bak
    echo "Created backup of mypy_fix/run-mypy-fixed.sh"
  fi
  
  # Update the run-mypy-fixed.sh script to exclude slack-app directory
  # Replace the command line that runs mypy
  sed -i 's#python3 -m mypy --config-file=mypy_fix/mypy.ini \\#python3 -m mypy --config-file=mypy_fix/mypy.ini \\#' mypy_fix/run-mypy-fixed.sh
  sed -i 's#    --explicit-package-bases \\#    --explicit-package-bases \\#' mypy_fix/run-mypy-fixed.sh
  sed -i 's#    --namespace-packages \\#    --namespace-packages \\#' mypy_fix/run-mypy-fixed.sh
  sed -i 's#    libs/ agents/ services/ tests/#    --exclude slack-app libs/ agents/ services/ tests/#' mypy_fix/run-mypy-fixed.sh
  
  echo "Updated mypy_fix/run-mypy-fixed.sh to exclude slack-app directory"
fi

# Update mypy.ini to include exclude patterns
if [ -f mypy_fix/mypy.ini ]; then
  # Backup original file if backup doesn't exist
  if [ ! -f mypy_fix/mypy.ini.bak ]; then
    cp mypy_fix/mypy.ini mypy_fix/mypy.ini.bak
    echo "Created backup of mypy_fix/mypy.ini"
  fi
  
  # Check if the exclude section already exists
  if ! grep -q "exclude =" mypy_fix/mypy.ini; then
    # Add exclude section to mypy.ini
    cat >> mypy_fix/mypy.ini << 'MYPY_INI'

# Excluded directories and files
exclude = [
    'slack-app',
    '.*/tests/.*',
    'services/mission-control.old',
]

[[mypy.overrides]]
module = "slack-app.*"
ignore_errors = true
MYPY_INI
    echo "Updated mypy_fix/mypy.ini with exclusion patterns"
  else
    echo "mypy_fix/mypy.ini already has exclusion patterns"
  fi
fi

# Create a pyproject.toml with mypy configuration if it doesn't have the mypy section
if [ -f pyproject.toml ]; then
  # Check if tool.mypy section exists
  if ! grep -q "\[tool\.mypy\]" pyproject.toml; then
    # Add mypy section to pyproject.toml
    cat >> pyproject.toml << 'PYPROJECT'

[tool.mypy]
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
disallow_incomplete_defs = true
check_untyped_defs = true
disallow_untyped_decorators = true
no_implicit_optional = true
strict_optional = true
namespace_packages = true
explicit_package_bases = true
exclude = [
    'slack-app',
    '.*/tests/.*',
    'services/mission-control.old',
]

[[tool.mypy.overrides]]
module = "slack-app.*"
ignore_errors = true
PYPROJECT
    echo "Updated pyproject.toml with mypy configuration"
  else
    echo "pyproject.toml already has mypy configuration"
  fi
fi

echo "Mypy configuration fix completed."
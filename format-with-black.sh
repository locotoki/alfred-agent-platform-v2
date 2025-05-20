#!/bin/bash
# Script to apply black formatting to the entire codebase

# Get Python version (prefer python3, fallback to python)
if command -v python3 &> /dev/null; then
  PYTHON_CMD=python3
elif command -v python &> /dev/null; then
  PYTHON_CMD=python
else
  echo "Error: Python not found. Please install Python."
  exit 1
fi

# Install Black
echo "Installing Black formatter..."
$PYTHON_CMD -m pip install black==24.4.2

# Format codebase with Black
echo "Formatting code with Black..."
# Use configuration from pyproject.toml
$PYTHON_CMD -m black .

# Report completion
echo "Black formatting complete\!"

#!/bin/bash
# Script to apply black formatting to the entire codebase
echo "Setting up Black formatter..."
python3 -m pip install black==24.4.2 || pip install black==24.4.2

echo "Running Black formatter on entire codebase..."
# Use configuration from pyproject.toml
black .

echo "Black formatting complete."

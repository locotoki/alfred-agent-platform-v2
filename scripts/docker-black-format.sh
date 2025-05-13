#!/bin/bash
# Script to format the entire codebase with black using Docker

# Use Docker to run black
echo "Running black formatter using Docker..."
docker run --rm -v "$(pwd):/app" -w /app python:3.11-slim bash -c "pip install black==24.1.1 && black ."

# Show completed message
echo "Black formatting complete."
echo "The changes are now ready to be committed."
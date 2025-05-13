#!/bin/bash
# Script to format the entire codebase with black

# Use the local Python environment if available
if command -v python3 &> /dev/null; then
    PYTHON=python3
elif command -v python &> /dev/null; then
    PYTHON=python
else
    echo "ERROR: No Python interpreter found."
    exit 1
fi

# Check if pip is available
if ! $PYTHON -m pip --version &> /dev/null; then
    echo "ERROR: pip is not available. Please install pip."
    exit 1
fi

# Install black if not already installed
if ! $PYTHON -m black --version &> /dev/null; then
    echo "Installing black version 24.1.1..."
    $PYTHON -m pip install black==24.1.1
fi

# Run black on the entire codebase
echo "Formatting codebase with black..."
$PYTHON -m black .

# Show which files were reformatted
echo "Black formatting complete."
echo "The changes are now ready to be committed."
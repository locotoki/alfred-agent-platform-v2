# Code Style Guide

This document provides guidelines and instructions for maintaining consistent code style across the Alfred Agent Platform v2 codebase.

## Python Style Standards

The codebase follows these style guidelines:

- **Black** for code formatting with line length set to 100 characters
- **isort** for import sorting with Black-compatible settings
- **flake8** for linting
- **mypy** for type checking

## How to Format Your Code

### Option 1: Using the Format Script (Recommended)

The project includes a format script that will apply both isort and Black formatting:

```bash
# Format the entire codebase
./scripts/format.sh

# Format a specific file or directory
./scripts/format.sh path/to/file.py
./scripts/format.sh path/to/directory
```

### Option 2: Using Pre-commit Hooks

The project includes pre-commit hooks that automatically check formatting on commit:

1. Install pre-commit hooks:
   ```bash
   pip install pre-commit
   pre-commit install
   ```

2. The hooks will run automatically on each commit
3. If a hook fails, it will show the issue and prevent the commit
4. Fix the issues and try committing again

### Option 3: Manual Formatting

You can also run the formatting tools manually:

```bash
# Sort imports
isort .

# Format code
black .
```

## CI/CD Integration

The CI pipeline includes style checks that will fail if code is not properly formatted. Always format your code before pushing to avoid CI failures.

## Style Configuration

Style configuration is defined in the following files:

- **pyproject.toml**: Contains configurations for Black, isort, and mypy
- **.pre-commit-config.yaml**: Contains pre-commit hook configurations

## Import Order Guidelines

Imports should be sorted in the following order (handled automatically by isort):

1. Python standard library imports
2. Third-party library imports
3. Local application imports
4. Relative imports

For example:

```python
# Standard library
import os
from datetime import datetime
from typing import Dict, List

# Third-party libraries
import numpy as np
import pandas as pd
from pydantic import BaseModel

# Local imports
from libs.agent_core import BaseAgent
from libs.a2a_adapter import A2AEnvelope

# Relative imports
from .models import MyModel
from .utils import helper_function
```

## Type Hints

Always use type hints for function parameters and return values:

```python
def process_data(input_data: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Process the input data and return results."""
    result: Dict[str, Any] = {}
    # ... processing logic
    return result
```

## Comments and Docstrings

- Use docstrings for all public classes and functions
- Follow Google-style docstring format
- Include parameter types, return types, and explanations

Example:

```python
def calculate_metrics(data: pd.DataFrame, threshold: float = 0.5) -> Dict[str, float]:
    """Calculate performance metrics for the given data.

    Args:
        data: DataFrame containing the input data with columns 'prediction' and 'actual'
        threshold: Decision threshold for binary classification

    Returns:
        Dictionary containing metrics (accuracy, precision, recall, f1)

    Raises:
        ValueError: If data is empty or required columns are missing
    """
    # Implementation
```

# Python Module Organization Guidelines

This document provides guidelines and standards for Python module organization in the Alfred Agent Platform v2 project.

## Module Organization

### Shared Libraries

- `/libs/` - Core shared libraries used across services
  - `/libs/agent_core/` - Core agent functionality
    - `/libs/agent_core/health/` - Health check standardization
    - `/libs/agent_core/base_agent.py` - Base agent implementation
  - `/libs/a2a_adapter/` - Agent-to-agent communication
  - `/libs/observability/` - Logging, metrics, and tracing

### Agents

- `/agents/` - Agent implementations
  - `/agents/<agent_name>/` - Specific agent package
    - `__init__.py` - Package initialization
    - `agent.py` - Main agent implementation
    - `models.py` - Data models
    - `chains.py` - Chain definitions
    - `/tests/` - Agent-specific tests

### Services

- `/services/` - Service implementations
  - `/services/<service_name>/` - Specific service
    - `/app/` - Service application code
      - `main.py` - Service entry point
    - `Dockerfile` - Service container definition

### Tests

- `/tests/` - Global test directory
  - `/unit/` - Unit tests
  - `/integration/` - Integration tests
  - `/e2e/` - End-to-end tests

## Package Structure

- All shared functionality should be organized in proper packages with clear namespaces
- Packages should have descriptive names that avoid common generic terms
- Each package should have a well-defined responsibility

## Import Conventions

Always use absolute imports from the project root:

```python
# Good
from libs.agent_core.health import create_health_app
from agents.financial_tax.models import TaxReport

# Avoid
from ..models import TaxReport  # Relative import
import agent_core.health  # Incomplete import path
```

## Module Naming

- Use descriptive, specific names for modules
- Avoid generic names like `app.py`, `utils.py`, or `common.py`
- When module functionality grows, consider splitting into a package

## Test Organization

- Use the same package structure in tests as in the implementation
- Add `__init__.py` files to all test directories
- Name test files with a `test_` prefix
- Group tests by module functionality

## CI Configuration

The CI pipeline is configured to enforce these standards:

1. **Linting checks**: `black`, `isort`, `flake8`, and `mypy`
2. **Unit tests**: Run with proper module isolation
3. **Health validation**: Check health module structure

## Migration Strategy

When refactoring existing code:

1. Move from flat modules to package structures
2. Update import statements to use absolute imports
3. Fix circular dependencies
4. Add proper `__init__.py` files
5. Update tests to match new structure

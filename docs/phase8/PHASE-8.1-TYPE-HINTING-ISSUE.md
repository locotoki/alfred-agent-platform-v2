# Phase 8.1: Add Type Hinting to alfred.* Namespace

## Overview
Following the successful namespace refactor in Phase 7D, we need to add comprehensive type hints to all modules in the `alfred.*` namespace to achieve full mypy strict compliance.

## Current State
- ✅ Namespace refactor complete (PR #66)
- ✅ Mypy strict mode enabled
- ⚠️ 164 type errors captured in baseline
- 🔴 Many modules lack type hints

## Objectives
1. Add type hints to all functions, methods, and classes
2. Achieve zero mypy errors in strict mode
3. Improve code maintainability and IDE support
4. Enable better refactoring capabilities

## Task Breakdown

### 1. Metrics Module (`alfred/metrics/`)
- [ ] Add type hints to `db_metrics.py`
- [ ] Add type hints to `metrics_collector.py`
- [ ] Add type hints to `pubsub_metrics.py`

### 2. Core Module (`alfred/core/`)
- [ ] Add type hints to `app/__init__.py`
- [ ] Add type hints to all core components

### 3. Model Module (`alfred/model/`)
- [ ] Add type hints to `router/main.py`
- [ ] Add type hints to `registry/main.py`
- [ ] Add type hints to health check components

### 4. Remediation Module (`alfred/remediation/`)
- [ ] Add type hints to `graphs.py`
- [ ] Add type hints to `settings.py`

### 5. Slack Module (`alfred/slack/`)
- [ ] Add type hints to `app.py`
- [ ] Add type hints to `run.py`

### 6. UI Module (`alfred/ui/`)
- [ ] Add type hints to `streamlit_chat.py`

### 7. Infrastructure & Support Modules
- [ ] Add type hints to `alfred/infrastructure/`
- [ ] Add type hints to `alfred/llm/`
- [ ] Add type hints to `alfred/rag/`

## Implementation Guidelines

### Type Hint Examples
```python
# Function with basic types
def process_metric(name: str, value: float) -> dict[str, Any]:
    return {"metric": name, "value": value}

# Function with optional parameters
def create_app(config: Optional[Config] = None) -> Flask:
    app = Flask(__name__)
    if config:
        app.config.from_object(config)
    return app

# Class with typed attributes
class MetricsCollector:
    def __init__(self, service_name: str) -> None:
        self.service_name: str = service_name
        self.metrics: dict[str, float] = {}
    
    def add_metric(self, name: str, value: float) -> None:
        self.metrics[name] = value
```

### Common Imports
```python
from typing import Any, Dict, List, Optional, Tuple, Union
from collections.abc import Callable, Iterator
```

## Testing Strategy
1. Run `mypy alfred/` after each module update
2. Ensure all tests still pass
3. Update tests to include type checking
4. Add type stubs for external dependencies if needed

## Success Criteria
- [ ] Zero mypy errors in strict mode
- [ ] All public APIs have complete type hints
- [ ] Documentation updated with type information
- [ ] CI pipeline validates type safety

## Dependencies
- Python 3.11+ (for latest typing features)
- mypy >= 1.0.0
- typing-extensions for backward compatibility

## Timeline
Estimated: 2-3 weeks
- Week 1: Core modules and metrics
- Week 2: Model, remediation, and Slack
- Week 3: UI, infrastructure, and cleanup

## Related Issues
- Follows: #66 (Phase 7D Namespace Refactor)
- Related: #67 (Documentation Update)

## Notes
- Start with the most critical modules (metrics, core)
- Use gradual typing approach where complex
- Consider using Protocol classes for interfaces
- Document any typing challenges or patterns discovered
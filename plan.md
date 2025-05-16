# MyPy Hygiene Action Plan

## Current State Assessment

### Configuration Comparison

The project currently has two MyPy configurations:
1. Root configuration (`mypy.ini`) - Less strict, with many error codes disabled
2. Fix directory configuration (`mypy_fix/mypy.ini`) - Strict configuration intended for future use

Key differences identified in the strict configuration:
- Enforces type annotations (`disallow_untyped_defs = True`)
- Requires complete type annotations (`disallow_incomplete_defs = True`)
- Adds several warnings for better type safety
- Enables namespace packages (`namespace_packages = True`)
- Uses explicit package bases (`explicit_package_bases = True`)

### Current Error Count

Running MyPy in strict mode on the `libs/` directory produces approximately 40 errors, primarily:
- Missing return type annotations
- Missing type parameters for generic types (e.g., `dict`, `Callable`)
- Untyped function definitions

### Namespace Pattern Issues

Our analysis shows inconsistent import patterns across modules:
- No consistent package namespace structure
- Potential for module name conflicts
- Missing `__init__.py` files in some packages
- Lack of proper namespace hierarchy

## Phased Implementation Plan

### Phase 1: Core Libraries (Week 1-2)

**Target Modules:**
- `libs/agent_core/health/`
- `libs/observability/`
- `libs/a2a_adapter/`

**Tasks:**
1. Add missing type annotations to core utility functions
2. Fix generic type parameter issues in dictionaries and callables
3. Add proper return type annotations
4. Update namespace pattern with explicit imports

**Configuration Changes:**
- Keep current root configuration to avoid breaking CI
- Implement stricter checks only on fixed modules

### Phase 2: Service Modules (Week 2-3)

**Target Modules:**
- `services/pubsub/`
- `services/model-registry/`
- `services/model-router/`
- `services/db-metrics/`

**Tasks:**
1. Apply namespace standards from Phase 1
2. Add type annotations to service interfaces
3. Fix generic type parameters
4. Ensure consistent import patterns

### Phase 3: Test Coverage (Week 3-4)

**Target Modules:**
- `tests/unit/`
- `tests/integration/`

**Tasks:**
1. Add type annotations to test fixtures
2. Standardize test utility functions
3. Ensure proper typing for mocks and test helpers

### Phase 4: CI Integration & Final Configuration (Week 4)

**Tasks:**
1. Merge the improved configuration to root `mypy.ini`
2. Update CI pipeline to enforce selected strict flags
3. Add documentation on type annotation standards
4. Create pre-commit hooks for type checking

## Configuration Updates

The following flags will be gradually migrated to the root configuration:

```ini
# Phase 1
warn_return_any = True
check_untyped_defs = True
warn_no_return = True
warn_unreachable = True

# Phase 2
disallow_untyped_defs = True 
warn_unused_configs = True
warn_redundant_casts = True

# Phase 3
disallow_incomplete_defs = True
no_implicit_optional = True
strict_optional = True

# Phase 4
namespace_packages = True
explicit_package_bases = True
disallow_untyped_decorators = True
```

## Namespace Standardization Approach

1. **Module Naming Convention:**
   - Use snake_case for module names
   - Group related functionality in packages
   - Use descriptive names that indicate purpose

2. **Import Structure:**
   - Always use absolute imports
   - Import specific functions/classes rather than whole modules
   - Group standard library, third-party, and local imports

3. **Package Organization:**
   - Ensure all packages have `__init__.py`
   - Use consistent submodule organization patterns
   - Avoid circular dependencies

## Implementation Strategy

This plan will be executed incrementally to avoid disrupting ongoing development:

1. **Isolated Improvements:**
   - Target specific modules in isolation
   - Use per-module configuration overrides
   - Keep CI pipeline passing throughout

2. **Gradual Configuration Updates:**
   - Incrementally add strict flags to root configuration
   - Monitor error counts to track progress
   - Use baseline report as a burndown reference

3. **Documentation:**
   - Document type annotation patterns and examples
   - Create a typing cheat sheet for common patterns
   - Update contributor guidelines

## Acceptance Criteria

- All core libraries have proper type annotations
- MyPy runs with no errors in strict mode on modified modules
- CI pipeline includes MyPy checks with appropriate strictness
- Import and namespace patterns are standardized
- Documentation on typing standards is available
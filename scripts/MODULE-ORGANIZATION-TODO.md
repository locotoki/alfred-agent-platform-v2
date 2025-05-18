# Python Module Organization Follow-up

## Background

During the health check standardization PR (#25), we encountered several Python module organization issues that complicated the CI process. These issues were temporarily worked around to allow the health check standardization to proceed, but they should be properly fixed in a dedicated PR.

## Issues Identified

1. Duplicate module names across the codebase:
   - Multiple `app.py` files in different services (`rag-gateway/src/app.py`, `services/*/app.py`)
   - Module access path conflicts (e.g., `agent_core.base_agent` vs `libs.agent_core.base_agent`)
   - Import path inconsistencies (`from financial_tax.models` vs `from agents.financial_tax.models`)

2. Import issues in test files:
   - Missing `__init__.py` files in some test directories
   - Inconsistent import paths in test files
   - Dependency loading issues in `tests/conftest.py`

## Proposed Solutions

1. Standardize module structure:
   - Ensure consistent import paths by adding proper `__init__.py` files
   - Rename modules with generic names (like `app.py`) to be more specific
   - Create a proper Python package structure

2. Update import statements:
   - Fix relative imports to use consistent patterns
   - Update test files to use correct import paths
   - Ensure test dependencies are properly installed

3. Improve CI configuration:
   - Update the CI pipeline to handle Python imports correctly
   - Add proper exclusions for duplicated code without using temporary workarounds
   - Standardize test environment setup

## Implementation Plan

1. Create a dedicated branch for module organization (e.g., `fix/python-module-organization`)
2. Fix the directory structure and module naming
3. Update import statements across the codebase
4. Update test files and configurations
5. Remove temporary workarounds from the health check PR
6. Submit PR with these changes

## Priority

This task should be prioritized after merging the health check standardization PR, as it affects multiple parts of the codebase and will improve overall maintainability.

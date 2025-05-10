# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands
- Setup: `make init`
- Build all services: `make build` 
- Run all tests: `make test`
- Run specific test types: `make test-unit`, `make test-integration`, `make test-e2e`
- Run single test: `python -m pytest path/to/test_file.py::test_function_name -v`
- Lint code: `make lint`
- Format code: `make format`

## Code Style Guidelines
- Python version: 3.11+
- Line length: 100 characters
- Formatting: Black
- Import sorting: isort with black profile
- Type hints: Required (disallow_untyped_defs=true)
- Naming: snake_case for variables/functions, PascalCase for classes
- Error handling: Use structured logging with context (`logger.error("message", error=str(e), context=value)`)
- Testing: pytest with markers for unit/integration/e2e
- Logging: Use structlog with context attributes
- Documentation: Docstrings required for public functions and classes
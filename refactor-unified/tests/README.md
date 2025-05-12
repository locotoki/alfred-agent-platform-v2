# Alfred Agent Platform v2 - Tests

This directory contains test scripts for validating the Docker Compose configuration and Alfred management script.

## Available Tests

### 1. Compose File Validation (`validate-compose.sh`)

Validates the Docker Compose files and their combinations:
- Validates individual Docker Compose files
- Validates common combinations of Docker Compose files

### 2. Alfred Script Test (`test-alfred-script.sh`)

Tests the Alfred management script functionality:
- Validates help command
- Tests argument parsing
- Checks network management functions

### 3. Service Health Test (`test-service-health.sh`)

Tests service health check configurations:
- Validates that all services have health checks defined
- Validates that health check test commands are properly formatted

### 4. Core Services Validation (`validate-core-services.sh`)

Validates core services configuration:
- Checks that critical core services are defined
- Validates that the Docker Compose configuration for core services is valid

### 5. Run All Tests (`run-all-tests.sh`)

Runs all test scripts in sequence and provides a summary.

## Running Tests

To run a specific test:
```bash
cd /path/to/alfred-agent-platform-v2/refactor-unified
./tests/test-name.sh
```

To run all tests:
```bash
cd /path/to/alfred-agent-platform-v2/refactor-unified
./tests/run-all-tests.sh
```

## Environment Setup

Tests use the `.env` file in the refactor-unified directory for environment variables. A sample `.env` file with test values is included.

## Test Results

Tests will output detailed information about the validation process and any issues found. A summary is provided at the end of each test run.

## Notes

- All tests are designed to run in a validation/test environment without starting actual containers
- For real deployment testing, use the Alfred script directly in a development environment
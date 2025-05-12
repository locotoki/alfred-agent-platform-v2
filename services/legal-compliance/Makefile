.PHONY: test test-unit test-integration test-e2e clean

# Run all tests
test:
	pytest

# Run only unit tests
test-unit:
	pytest tests/unit -v

# Run only integration tests
test-integration:
	pytest tests/integration -v

# Run only end-to-end tests
test-e2e:
	RUN_E2E_TESTS=true pytest tests/e2e -v

# Clean temporary files
clean:
	rm -rf .pytest_cache
	rm -rf .coverage
	rm -rf __pycache__
	rm -rf app/__pycache__
	rm -rf tests/__pycache__
	rm -rf tests/*/__pycache__
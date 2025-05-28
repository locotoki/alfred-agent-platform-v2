# E2E Testing Runbook

## Overview

This runbook covers the E2E smoke and regression test suite for the Alfred platform, including the `/alfred health` CLI command and Slack integration tests.

## Test Categories

### 1. Smoke Tests (`test_smoke.py`)
- **Purpose**: Quick validation of core service health
- **Duration**: < 2 minutes
- **Coverage**:
  - Core service health endpoints
  - Database connectivity
  - Metrics endpoints

### 2. Regression Tests (`test_regression.py`)
- **Purpose**: Comprehensive platform stability validation
- **Duration**: 5-10 minutes
- **Coverage**:
  - Agent orchestration flow
  - Data persistence
  - Error handling
  - Rate limiting
  - Metrics collection

### 3. Slack Integration Tests (`test_slack_integration.py`)
- **Purpose**: Validate Slack integrations
- **Duration**: < 2 minutes
- **Coverage**:
  - Alert delivery
  - MCP Gateway health
  - Bot command handling

## Running Tests Locally

### Prerequisites
```bash
# Install dependencies
pip install pytest pytest-timeout requests rich click

# Ensure services can start
docker-compose --version
```

### Quick Smoke Test
```bash
# Just smoke tests (default)
./scripts/run-e2e-tests.sh
```

### Full Test Suite
```bash
# All tests including regression and Slack
./scripts/run-e2e-tests.sh --all
```

### Specific Test Categories
```bash
# Regression tests only
./scripts/run-e2e-tests.sh --regression

# Slack tests only (requires SLACK_WEBHOOK_URL)
./scripts/run-e2e-tests.sh --slack
```

## Alfred Health CLI

### Basic Usage
```bash
# Check all services
./alfred-cli health

# Check only critical services
./alfred-cli health --critical-only

# JSON output for automation
./alfred-cli health --json
```

### Exit Codes
- `0`: All critical services healthy
- `1`: One or more critical services unhealthy

### Service Categories
- **Critical**: alfred-core, ui-chat, agent-orchestrator, model-registry, db-postgres, redis
- **Non-critical**: prometheus, grafana, alertmanager, crm-sync

## CI Integration

E2E tests run automatically on:
- Every PR (smoke tests)
- Merges to main (full suite)
- Manual workflow dispatch

### CI Workflow
1. **e2e-smoke** job runs first (required)
2. **e2e-regression** job runs if smoke passes
3. Services are started with health checks
4. Tests execute with timeouts
5. Logs collected on failure

## Troubleshooting

### Services Won't Start
```bash
# Check existing containers
docker ps -a

# Clean up
docker-compose down -v

# Check ports
lsof -i :8011,8012,3001,5432,6379
```

### Tests Timing Out
```bash
# Check service health manually
docker-compose ps
curl -f http://localhost:8011/health

# View service logs
docker-compose logs alfred-core -f
```

### Slack Tests Failing
```bash
# Verify webhook URL
echo $SLACK_WEBHOOK_URL

# Test webhook manually
curl -X POST $SLACK_WEBHOOK_URL \
  -H 'Content-Type: application/json' \
  -d '{"text": "Test message"}'
```

## Adding New Tests

### 1. Create test file in `tests/e2e/`
```python
@pytest.mark.e2e
def test_new_feature(http_client, wait_for_services):
    """Test description."""
    response = http_client.get("http://service:port/endpoint")
    assert response.status_code == 200
```

### 2. Add service to health checks
Update `CORE_SERVICES` in `alfred/cli/health.py`

### 3. Update CI if needed
Add service to `wait_for_services` fixture in `conftest.py`

## Maintenance

### Weekly Tasks
- [ ] Review test execution times
- [ ] Update service health endpoints
- [ ] Check for flaky tests

### Monthly Tasks
- [ ] Audit test coverage
- [ ] Update regression scenarios
- [ ] Review CI performance

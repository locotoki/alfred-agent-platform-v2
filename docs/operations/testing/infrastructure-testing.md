# Infrastructure Component: Infrastructure Testing

*Last Updated: 2025-05-13*  
*Owner: QA Team*  
*Status: Active*

## Overview

This document describes the infrastructure testing framework for the Alfred Agent Platform v2. The testing infrastructure enables comprehensive validation of the platform's components, ensuring reliability, performance, and security. The framework includes unit tests, integration tests, end-to-end tests, load testing, and security testing, providing a multi-layered approach to quality assurance across different environments.

## Architecture

The testing infrastructure architecture spans across all layers of the Alfred Agent Platform v2:

```mermaid
graph TB
    subgraph "Test Types"
        unit[Unit Tests]
        integration[Integration Tests]
        e2e[End-to-End Tests]
        performance[Performance Tests]
        security[Security Tests]
        infrastructure[Infrastructure Tests]
    end
    
    subgraph "Test Environments"
        local[Local Development]
        ci[CI Environment]
        staging[Staging Environment]
        production[Production Environment]
    end
    
    subgraph "Test Tooling"
        pytest[Pytest Framework]
        playwright[Playwright]
        k6[K6 Load Testing]
        trivy[Trivy Security Scanner]
        terraform_test[Terraform Testing]
        mockito[Test Mocks]
    end
    
    subgraph "Test Data Management"
        fixtures[Test Fixtures]
        mock_data[Mock Data]
        test_db[Test Databases]
    end
    
    unit --> pytest
    integration --> pytest
    e2e --> playwright
    performance --> k6
    security --> trivy
    infrastructure --> terraform_test
    
    pytest --> local
    pytest --> ci
    playwright --> local
    playwright --> ci
    k6 --> staging
    trivy --> ci
    terraform_test --> ci
    
    fixtures --> pytest
    mock_data --> playwright
    test_db --> pytest
```

## Test Framework Configuration

### Unit Testing Configuration

Unit tests are built using pytest with the following configuration:

```python
# conftest.py - Core pytest configuration
import pytest
import asyncio
import os
from typing import Generator
from unittest.mock import AsyncMock, MagicMock
import asyncpg
import redis
from google.cloud import pubsub_v1

from libs.a2a_adapter import PubSubTransport, SupabaseTransport, PolicyMiddleware

@pytest.fixture(scope="session")
def event_loop() -> Generator:
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(autouse=True)
def setup_test_env():
    """Set up test environment variables."""
    os.environ["ENVIRONMENT"] = "test"
    os.environ["PUBSUB_EMULATOR_HOST"] = "localhost:8085"
    os.environ["DATABASE_URL"] = "postgresql://postgres:postgres@localhost:5432/test_db"
    os.environ["REDIS_URL"] = "redis://localhost:6379/1"
    os.environ["GCP_PROJECT_ID"] = "test-project"

@pytest.fixture
async def test_db():
    """Provide a clean test database."""
    conn = await asyncpg.connect(os.environ["DATABASE_URL"])
    
    # Clean up existing data
    await conn.execute("TRUNCATE TABLE tasks, task_results, processed_messages CASCADE")
    
    yield conn
    
    await conn.close()

@pytest.fixture
def mock_pubsub():
    """Mock Pub/Sub client."""
    mock = MagicMock(spec=pubsub_v1.PublisherClient)
    mock.publish.return_value.result.return_value = "test-message-id"
    return mock

@pytest.fixture
def mock_redis():
    """Mock Redis client."""
    return MagicMock(spec=redis.Redis)
```

Pytest configuration in `pyproject.toml`:

```toml
[tool.pytest]
testpaths = ["tests"]
python_files = "test_*.py"
python_classes = "Test*"
python_functions = "test_*"
markers = [
    "unit: Unit tests",
    "integration: Integration tests",
    "e2e: End-to-end tests",
]
```

### End-to-End Testing Configuration

E2E tests are built using Playwright with the following configuration:

```typescript
// playwright.config.ts
import { PlaywrightTestConfig } from '@playwright/test';

const config: PlaywrightTestConfig = {
  testDir: './tests',
  timeout: 120000, // Longer timeout for YouTube workflows 
  fullyParallel: false, 
  retries: 1,
  workers: 1, // Sequential execution to avoid conflicts
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3005', // Mission Control UI port
    viewport: { width: 1280, height: 720 },
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
    trace: 'on-first-retry',
    headless: false, // Useful for debugging
  },
  projects: [
    {
      name: 'chromium',
      use: { browserName: 'chromium' },
    },
  ],
};

export default config;
```

### Performance Testing Configuration

Performance tests are configured using K6:

```javascript
// k6-config.js
export const options = {
  scenarios: {
    basic_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 50 },   // Ramp up to 50 users over 1 minute
        { duration: '5m', target: 50 },   // Stay at 50 users for 5 minutes
        { duration: '1m', target: 0 },    // Ramp down to 0 users over 1 minute
      ],
      gracefulRampDown: '30s',
    },
    stress_test: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 100 },  // Ramp up to 100 users over 2 minutes
        { duration: '5m', target: 100 },  // Stay at 100 users for 5 minutes
        { duration: '2m', target: 200 },  // Ramp up to 200 users over 2 minutes
        { duration: '5m', target: 200 },  // Stay at 200 users for 5 minutes
        { duration: '2m', target: 0 },    // Ramp down to 0 users over 2 minutes
      ],
      gracefulRampDown: '30s',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests should complete within 500ms
    http_req_failed: ['rate<0.01'],   // Less than 1% of requests should fail
  },
};
```

### Infrastructure Testing Configuration

Terraform testing is configured using Terratest:

```go
// main_test.go
package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestAlfredPlatformInfrastructure(t *testing.T) {
	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform/environments/dev",
		Vars: map[string]interface{}{
			"environment": "test",
			"region":      "us-west-2",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Test output values
	vpcId := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcId, "VPC ID should not be empty")

	subnetIds := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
	assert.Equal(t, 3, len(subnetIds), "There should be 3 private subnets")
}
```

## Test Types and Implementation

### Unit Tests

Unit tests validate individual functions and classes in isolation:

```python
# tests/unit/test_base_agent.py
import pytest
from unittest.mock import AsyncMock
from agents.base_agent import BaseAgent

class TestBaseAgent:
    @pytest.fixture
    def agent(self):
        """Create a test agent."""
        return BaseAgent(name="test-agent")
    
    @pytest.mark.asyncio
    async def test_process_message(self, agent, mock_pubsub):
        """Test message processing."""
        # Setup
        message = {"id": "test-id", "intent": "test-intent", "content": {}}
        agent.transport = AsyncMock()
        agent.process_intent = AsyncMock()
        
        # Execute
        await agent.process_message(message)
        
        # Verify
        agent.process_intent.assert_called_once_with("test-intent", {})
```

Test command:

```bash
# Run unit tests
python -m pytest tests/unit/ -v
```

### Integration Tests

Integration tests verify the interaction between components:

```python
# tests/integration/test_exactly_once_processing.py
import pytest
import asyncio
from uuid import uuid4

@pytest.mark.asyncio
@pytest.mark.integration
async def test_exactly_once_processing(supabase_transport, policy_middleware):
    """Test that messages are processed exactly once."""
    # Setup
    message_id = str(uuid4())
    
    # First attempt should succeed
    result1 = await policy_middleware.should_process(message_id)
    assert result1 is True
    
    # Record message as processed
    await supabase_transport.record_processed_message(message_id)
    
    # Second attempt should fail
    result2 = await policy_middleware.should_process(message_id)
    assert result2 is False
```

Test command:

```bash
# Run integration tests
python -m pytest tests/integration/ -v -m integration
```

### End-to-End Tests

E2E tests validate entire workflows from the user's perspective:

```typescript
// tests/e2e/tests/niche-scout.spec.ts
import { test, expect } from '@playwright/test';
import { login, navigateToWorkflow } from './utils';

test('Niche Scout Workflow', async ({ page }) => {
  // Login and navigate to Niche Scout
  await login(page);
  await navigateToWorkflow(page, 'niche-scout');
  
  // Enter search keyword
  await page.fill('[data-testid="keyword-input"]', 'sustainable gardening');
  await page.click('[data-testid="search-button"]');
  
  // Wait for results to load
  await page.waitForSelector('[data-testid="results-container"]', { timeout: 60000 });
  
  // Verify results are displayed
  const resultCount = await page.locator('[data-testid="result-card"]').count();
  expect(resultCount).toBeGreaterThan(0);
  
  // Verify report generation
  await page.click('[data-testid="generate-report"]');
  await page.waitForSelector('[data-testid="report-content"]', { timeout: 90000 });
  
  const reportText = await page.textContent('[data-testid="report-content"]');
  expect(reportText).toContain('sustainable gardening');
});
```

Test command:

```bash
# Run E2E tests
cd tests/e2e && npm test
```

### Performance Tests

Performance tests evaluate system behavior under load:

```javascript
// performance-tests/api-load-test.js
import http from 'k6/http';
import { sleep, check } from 'k6';
import { Counter } from 'k6/metrics';

// Custom metrics
const taskCreationErrors = new Counter('task_creation_errors');

// Import the test configuration
import { options } from './k6-config.js';

export { options };

export default function() {
  // Create a new task
  const payload = JSON.stringify({
    intent: 'process_data',
    content: {
      data: 'test-data',
      timestamp: new Date().toISOString()
    }
  });
  
  const params = {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${__ENV.API_TOKEN}`
    }
  };
  
  const createTaskResponse = http.post('http://agent-core:8011/api/tasks', payload, params);
  
  // Check if task creation was successful
  const createTaskCheck = check(createTaskResponse, {
    'Task created successfully': (r) => r.status === 201,
    'Has task ID': (r) => JSON.parse(r.body).task_id !== undefined
  });
  
  if (!createTaskCheck) {
    taskCreationErrors.add(1);
    console.error(`Failed to create task: ${createTaskResponse.status} ${createTaskResponse.body}`);
  }
  
  // Get task status (if task was created successfully)
  if (createTaskCheck) {
    const taskId = JSON.parse(createTaskResponse.body).task_id;
    const getTaskResponse = http.get(`http://agent-core:8011/api/tasks/${taskId}`, params);
    
    check(getTaskResponse, {
      'Get task successful': (r) => r.status === 200,
      'Task status exists': (r) => JSON.parse(r.body).status !== undefined
    });
  }
  
  sleep(1);
}
```

Test command:

```bash
# Run performance tests
k6 run performance-tests/api-load-test.js
```

### Security Tests

Security scanning for vulnerabilities:

```yaml
# trivy-config.yaml
severity:
  - CRITICAL
  - HIGH

scan:
  skip-dirs:
    - node_modules
    - .git
    - .github
    - docs

vuln:
  ignore-unfixed: true

misconfiguration:
  include:
    - kubernetes
    - terraform
    - dockerfile
```

Test command:

```bash
# Run security tests
trivy fs --config trivy-config.yaml .
```

### Infrastructure Tests

Tests for infrastructure validation:

```bash
#!/bin/bash
# infrastructure-tests/validate-k8s.sh

set -e

echo "Validating Kubernetes manifests..."

# Validate manifests with kubeval
find k8s -name "*.yaml" -type f -exec kubeval --strict --kubernetes-version 1.24.0 {} \;

echo "Checking Kubernetes resources for security issues..."

# Check for security issues with kube-score
find k8s -name "*.yaml" -type f -exec kube-score score {} \;

echo "All Kubernetes manifests validated successfully."
```

Test command:

```bash
# Run infrastructure tests
./infrastructure-tests/validate-k8s.sh
```

## Test Environments

### Local Development Environment

The local development environment is configured for quick feedback:

```bash
# Start local test environment
docker-compose -f docker-compose.yml -f docker-compose.test.yml up -d

# Verify test environment is running
curl http://localhost:8011/health
```

### CI Environment

The CI environment is configured in GitHub Actions:

```yaml
# .github/workflows/ci.yml (excerpt)
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -r requirements-dev.txt

      - name: Run tests with coverage
        run: |
          pytest tests/ -v --cov=./ --cov-report=xml --cov-report=html
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
          PUBSUB_EMULATOR_HOST: localhost:8085
```

### Staging Environment

Staging is configured to mirror production:

```bash
# Deploy to staging environment for testing
terraform apply -var-file=staging.tfvars

# Run end-to-end tests against staging
cd tests/e2e && npm run test:staging
```

## Test Data Management

### Test Fixtures

Test fixtures provide reusable test data:

```python
# tests/fixtures/tasks.py
import pytest
from uuid import uuid4

@pytest.fixture
def sample_task():
    """Create a sample task for testing."""
    return {
        "task_id": f"task-{uuid4()}",
        "intent": "process_data",
        "status": "pending",
        "content": {
            "data": "test-data",
            "options": {
                "priority": "high",
                "timeout": 30
            }
        },
        "priority": 2,
        "created_by": "test-user"
    }

@pytest.fixture
def sample_task_result():
    """Create a sample task result for testing."""
    return {
        "result_type": "data_processed",
        "content": {
            "processed_data": "test-processed-data",
            "processing_time": 0.5
        }
    }
```

### Test Databases

Test databases are created and configured for isolation:

```yaml
# docker-compose.test.yml (excerpt)
services:
  test-db:
    image: postgres:15
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: test_db
    ports:
      - "5432:5432"
    volumes:
      - ./migrations/supabase:/docker-entrypoint-initdb.d
    command: ["postgres", "-c", "fsync=off", "-c", "synchronous_commit=off", "-c", "full_page_writes=off"]
```

### Mock Data

Mock data services provide predictable test data:

```typescript
// tests/e2e/tests/utils.ts
export const mockNicheScoutResponse = {
  status: "success",
  data: {
    results: [
      {
        title: "Sustainable Gardening Techniques",
        videoId: "abc123",
        viewCount: 15000,
        engagement: 0.85,
        publishDate: "2024-12-01T12:00:00Z",
        thumbnailUrl: "https://example.com/thumbnail1.jpg"
      },
      {
        title: "Urban Permaculture Design",
        videoId: "def456",
        viewCount: 32000,
        engagement: 0.92, 
        publishDate: "2024-11-15T10:00:00Z",
        thumbnailUrl: "https://example.com/thumbnail2.jpg"
      }
    ],
    metrics: {
      totalVideos: 150,
      averageViews: 12500,
      averageEngagement: 0.78
    }
  }
};
```

## CI/CD Pipeline Integration

### Test Integration in CI/CD

Tests are integrated into the CI/CD pipeline:

```yaml
# .github/workflows/ci.yml (excerpt)
jobs:
  # Python linting and testing
  lint-and-test:
    needs: security-scan
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -r requirements-dev.txt

      - name: Run formatters check
        run: |
          black --check .
          isort --check-only .

      - name: Run linters
        run: |
          flake8 .
          mypy .
          bandit -r agents/ libs/ services/ -c pyproject.toml

      - name: Run tests with coverage
        run: |
          pytest tests/ -v --cov=./ --cov-report=xml --cov-report=html
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
          PUBSUB_EMULATOR_HOST: localhost:8085

      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          files: ./coverage.xml
          flags: unittests
          name: codecov-umbrella
          fail_ci_if_error: false
```

### Quality Gates

Quality gates enforce test quality standards:

```yaml
# .github/workflows/financial-tax-agent.yml (excerpt)
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      # ... (previous steps)
      
      - name: Check coverage
        run: |
          coverage report --fail-under=90
```

## Test Automation Infrastructure

### Automated Test Execution

Scheduled test runs ensure ongoing quality:

```yaml
# .github/workflows/scheduled-tests.yml
name: Scheduled Integration Tests

on:
  schedule:
    # Run every day at midnight UTC
    - cron: '0 0 * * *'
  workflow_dispatch:  # Allow manual triggering

jobs:
  integration-tests:
    runs-on: ubuntu-latest
    env:
      PYTHON_VERSION: "3.11"
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -r requirements-dev.txt
      
      - name: Run integration tests
        run: |
          pytest tests/integration/ -v -m integration
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
          PUBSUB_EMULATOR_HOST: localhost:8085
      
      - name: Notify on failure
        if: failure()
        uses: rtCamp/action-slack-notify@v2
        env:
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
          SLACK_CHANNEL: alerts
          SLACK_COLOR: danger
          SLACK_TITLE: Integration Tests Failed
          SLACK_MESSAGE: Daily integration tests failed. Check the logs for details.
```

### Test Helper Scripts

Helper scripts simplify test execution:

```bash
#!/bin/bash
# tests/e2e/run-tests.sh
set -e

# Check if Mission Control is running
if ! curl -s http://localhost:3005/health > /dev/null; then
  echo "Starting Mission Control..."
  docker-compose -f docker-compose.yml -f docker-compose.ui.yml up -d ui-admin
  echo "Waiting for Mission Control to start..."
  timeout 60 bash -c 'until curl -s http://localhost:3005/health > /dev/null; do sleep 2; done' || { echo "Mission Control failed to start"; exit 1; }
fi

# Check if Social Intelligence Agent is running
if ! curl -s http://localhost:9000/health > /dev/null; then
  echo "Starting Social Intelligence Agent..."
  docker-compose -f docker-compose.yml up -d agent-social
  echo "Waiting for Social Intelligence Agent to start..."
  timeout 60 bash -c 'until curl -s http://localhost:9000/health > /dev/null; do sleep 2; done' || { echo "Social Intelligence Agent failed to start"; exit 1; }
fi

# Install Playwright if needed
if ! [ -d "node_modules" ]; then
  echo "Installing dependencies..."
  npm install
  echo "Installing browsers..."
  npx playwright install chromium
fi

# Run the tests
echo "Running tests..."
npm test

echo "Tests completed successfully!"
```

## Monitoring and Reporting

### Test Metrics Collection

Test metrics are collected for analysis:

```yaml
# .github/workflows/ci.yml (excerpt)
- name: Upload test metrics
  if: always()
  run: |
    python -m scripts.test_metrics \
      --duration=${{ steps.test-timing.outputs.duration }} \
      --success=${{ job.status == 'success' }} \
      --tests=${{ steps.test-count.outputs.count }} \
      --failures=${{ steps.test-failures.outputs.count }}
```

### Test Reports

Test reports provide detailed results:

```bash
# Generate HTML test report
pytest tests/ --html=reports/test-report.html --self-contained-html

# Generate JUnit XML for CI integration
pytest tests/ --junitxml=reports/junit.xml
```

### Test Dashboards

Custom dashboards visualize test health:

```yaml
# grafana/dashboards/test-metrics.json (excerpt)
{
  "title": "Test Metrics Dashboard",
  "panels": [
    {
      "title": "Test Pass Rate",
      "type": "gauge",
      "datasource": "Prometheus",
      "targets": [
        {
          "expr": "sum(test_success_total) / sum(test_total) * 100",
          "refId": "A"
        }
      ],
      "options": {
        "thresholds": [
          {
            "color": "red",
            "value": 0
          },
          {
            "color": "yellow",
            "value": 90
          },
          {
            "color": "green",
            "value": 95
          }
        ]
      }
    },
    {
      "title": "Test Duration",
      "type": "timeseries",
      "datasource": "Prometheus",
      "targets": [
        {
          "expr": "rate(test_duration_seconds_sum[1d]) / rate(test_duration_seconds_count[1d])",
          "refId": "A"
        }
      ]
    }
  ]
}
```

## Cross-Environment Test Strategy

### Test Strategy by Environment

The test strategy varies by environment:

| Test Type | Local Dev | CI | Staging | Production |
|-----------|-----------|----|---------| ---------- |
| Unit Tests | Yes | Yes | No | No |
| Integration Tests | Yes | Yes | Yes | No |
| E2E Tests | Basic | Full | Full | Smoke Only |
| Performance Tests | No | Basic | Full | Monitoring |
| Security Tests | Basic | Full | Full | Monitoring |
| Infrastructure Tests | Basic | Full | Full | Limited |

### Environment-Specific Test Configuration

```yaml
# Test configuration for different environments
test_config:
  development:
    unit_tests: true
    integration_tests: true
    e2e_tests:
      enabled: true
      subset: "critical-paths"
    performance_tests:
      enabled: false
    security_tests:
      enabled: true
      scan_depth: "basic"
  
  ci:
    unit_tests: true
    integration_tests: true
    e2e_tests:
      enabled: true
      subset: "all"
    performance_tests:
      enabled: true
      duration: "short"
      thresholds:
        p95_response_time: 800
    security_tests:
      enabled: true
      scan_depth: "full"
  
  staging:
    unit_tests: false
    integration_tests: true
    e2e_tests:
      enabled: true
      subset: "all"
    performance_tests:
      enabled: true
      duration: "full"
      thresholds:
        p95_response_time: 500
    security_tests:
      enabled: true
      scan_depth: "full"
  
  production:
    unit_tests: false
    integration_tests: false
    e2e_tests:
      enabled: true
      subset: "smoke"
    performance_tests:
      enabled: false
    security_tests:
      enabled: true
      scan_depth: "critical-only"
```

## Best Practices

### Test Isolation

Ensure tests are isolated and don't affect each other:

```python
# test_isolation.py
import pytest

@pytest.mark.asyncio
async def test_isolated_database(test_db):
    """Test with an isolated database."""
    # Each test gets a fresh database state
    await test_db.execute("INSERT INTO tasks (task_id, intent, status) VALUES ('test-1', 'test', 'pending')")
    
    # Verify the data was inserted
    result = await test_db.fetchval("SELECT COUNT(*) FROM tasks WHERE task_id = 'test-1'")
    assert result == 1

@pytest.mark.asyncio
async def test_different_isolation(test_db):
    """Another test with an isolated database."""
    # This test should not see data from other tests
    result = await test_db.fetchval("SELECT COUNT(*) FROM tasks WHERE task_id = 'test-1'")
    assert result == 0
```

### Test Data Management

Properly manage test data to ensure reliability:

```python
# test_data_management.py
import pytest
import os
from unittest import mock

@pytest.fixture
def test_data_file():
    """Create and clean up a test data file."""
    # Create test file
    with open("test_data.json", "w") as f:
        f.write('{"test": "data"}')
    
    yield "test_data.json"
    
    # Clean up after the test
    if os.path.exists("test_data.json"):
        os.remove("test_data.json")

def test_file_processing(test_data_file):
    """Test processing a file with test data."""
    # Use the test data file
    with open(test_data_file, "r") as f:
        data = f.read()
    
    assert "test" in data
```

### Mock External Services

Mock external services to control test behavior:

```python
# test_external_services.py
import pytest
from unittest.mock import patch
from services.youtube_api import YouTubeAPI

def test_youtube_search():
    """Test YouTube search with mocked API."""
    # Mock the YouTube API response
    mock_response = {
        "items": [
            {
                "id": {"videoId": "abc123"},
                "snippet": {
                    "title": "Test Video",
                    "description": "Test Description",
                    "publishedAt": "2025-01-01T00:00:00Z"
                },
                "statistics": {
                    "viewCount": "1000",
                    "likeCount": "100"
                }
            }
        ]
    }
    
    # Patch the API request method
    with patch("services.youtube_api.YouTubeAPI._make_request", return_value=mock_response):
        api = YouTubeAPI(api_key="test-key")
        results = api.search("test query")
        
        assert len(results) == 1
        assert results[0]["title"] == "Test Video"
        assert results[0]["videoId"] == "abc123"
```

## Troubleshooting

### Common Issues

| Issue | Symptoms | Resolution |
|-------|----------|------------|
| Test database connection failures | `OperationalError: could not connect to server` | Ensure PostgreSQL container is running and accessible |
| Flaky E2E tests | Intermittent test failures | Increase timeouts, add retry logic, check for race conditions |
| Slow test execution | CI pipeline taking too long | Use test parallelization, optimize test dependencies |
| Mock data inconsistencies | Tests pass locally but fail in CI | Ensure consistent mock data across environments |
| Test isolation problems | Tests affect each other | Improve fixture cleanup, use transaction isolation |

### Debugging Tests

```python
# debugging_tests.py
import pytest
import logging

# Configure logging for tests
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

@pytest.fixture
def debug_fixture():
    """A fixture that logs debug information."""
    logger.debug("Setting up debug fixture")
    yield "debug-data"
    logger.debug("Tearing down debug fixture")

def test_with_debugging(debug_fixture):
    """A test with debug logging."""
    logger.debug(f"Running test with {debug_fixture}")
    
    # For additional debugging in CI
    if os.environ.get("CI") == "true":
        # Print environment information
        logger.debug(f"Python version: {sys.version}")
        logger.debug(f"Environment variables: {os.environ}")
        
        # Dump additional diagnostics
        logger.debug(f"Current directory contents: {os.listdir('.')}")
    
    assert True
```

## Related Components

- [CI/CD Pipeline Infrastructure](../ci-cd/ci-cd-pipeline-infrastructure.md)
- [Infrastructure Security](../security/infrastructure-security.md)
- [Monitoring Infrastructure](../monitoring/monitoring-infrastructure.md)
- [Docker Compose Configuration](../containerization/docker-compose-configuration.md)
- [Kubernetes Deployment](../containerization/kubernetes-deployment.md)

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0.0 | 2025-05-13 | Initial version | QA Team |

## References

- [Pytest Documentation](https://docs.pytest.org/)
- [Playwright Testing Documentation](https://playwright.dev/docs/intro)
- [K6 Performance Testing Documentation](https://k6.io/docs/)
- [Grafana Test Dashboards](https://grafana.com/grafana/dashboards/)
- [Testing Strategies in a Microservice Architecture](https://martinfowler.com/articles/microservice-testing/)
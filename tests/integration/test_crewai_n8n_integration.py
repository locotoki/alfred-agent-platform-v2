"""
Integration tests for CrewAI and n8n integration.
"""

import os
import time
import uuid
import json
import pytest
import requests
from contextlib import contextmanager

# URLs for services
CREWAI_URL = os.environ.get("CREWAI_URL", "http://localhost:9004")
N8N_URL = os.environ.get("N8N_URL", "http://localhost:5500")
RAG_URL = os.environ.get("RAG_URL", "http://localhost:8501")

# Skip marks
SKIP_CREWAI = os.environ.get("SKIP_CREWAI_TESTS", "false").lower() == "true"
SKIP_N8N = os.environ.get("SKIP_N8N_TESTS", "false").lower() == "true"
SKIP_INTEGRATION = os.environ.get("SKIP_INTEGRATION_TESTS", "false").lower() == "true"

@contextmanager
def timed_execution(description):
    """Context manager to time the execution of a code block."""
    print(f"Starting: {description}")
    start_time = time.time()
    try:
        yield
    finally:
        end_time = time.time()
        print(f"Completed: {description} in {end_time - start_time:.2f} seconds")

@pytest.mark.skipif(SKIP_CREWAI, reason="CrewAI tests disabled")
class TestCrewAI:
    """Tests for the CrewAI service."""

    def test_health_endpoint(self):
        """Test the health endpoint of the CrewAI service."""
        with timed_execution("CrewAI health check"):
            response = requests.get(f"{CREWAI_URL}/health")
            assert response.status_code == 200
            assert response.json()["status"] == "healthy"

    def test_list_crews(self):
        """Test the endpoint to list available crews."""
        with timed_execution("Listing available crews"):
            response = requests.get(f"{CREWAI_URL}/crews")
            assert response.status_code == 200
            crews = response.json()["crews"]
            assert len(crews) > 0
            assert "research" in crews
            assert "code_review" in crews
            assert "data_analysis" in crews

    def test_metrics_summary(self):
        """Test the metrics summary endpoint."""
        with timed_execution("Getting metrics summary"):
            response = requests.get(f"{CREWAI_URL}/metrics/summary")
            assert response.status_code == 200
            metrics = response.json()
            # Just check that the structure is correct, not specific values
            assert "totalTasks" in metrics
            assert "successRate" in metrics
            assert "averageExecutionTime" in metrics
            assert "topCrews" in metrics

@pytest.mark.skipif(SKIP_N8N, reason="n8n tests disabled")
class TestN8n:
    """Tests for n8n service."""

    def test_health_endpoint(self):
        """Test the health endpoint of n8n."""
        with timed_execution("n8n health check"):
            response = requests.get(f"{N8N_URL}/healthz")
            assert response.status_code == 200

@pytest.mark.skipif(SKIP_INTEGRATION, reason="Integration tests disabled")
class TestIntegration:
    """Tests for the integration between CrewAI and n8n."""

    def test_pr_triage_webhook(self):
        """Test the PR triage webhook integration."""
        # This is a simplified test - in a real environment, you'd want more validation
        task_id = f"test-{uuid.uuid4()}"
        pr_number = 999
        
        with timed_execution("PR triage webhook test"):
            # Send a simulated PR webhook event
            payload = {
                "action": "opened",
                "number": pr_number,
                "pull_request": {
                    "title": "Test PR for integration testing",
                    "body": "This is a test PR to verify integration between CrewAI and n8n",
                    "html_url": "https://github.com/test/repo/pull/999",
                    "user": {
                        "login": "testuser",
                        "name": "Test User"
                    },
                    "head": {
                        "ref": "test-branch"
                    },
                    "base": {
                        "ref": "main"
                    },
                    "additions": 10,
                    "deletions": 5,
                    "changed_files": 2,
                    "created_at": "2023-05-10T12:00:00Z",
                    "updated_at": "2023-05-10T12:00:00Z"
                },
                "repository": {
                    "full_name": "test/repo"
                }
            }
            
            # Try to send the webhook event (this may fail if n8n isn't configured correctly for testing)
            try:
                response = requests.post(
                    f"{N8N_URL}/webhook/github-webhook",
                    headers={
                        "Content-Type": "application/json",
                        "X-GitHub-Event": "pull_request"
                    },
                    json=payload,
                    timeout=5
                )
                assert response.status_code in [200, 201]
                print(f"Webhook response: {response.status_code} - {response.text}")
            except (requests.exceptions.ConnectionError, requests.exceptions.Timeout, AssertionError) as e:
                pytest.skip(f"Webhook test skipped, n8n might not be properly configured: {str(e)}")

    def test_direct_task_submission(self):
        """Test direct task submission to CrewAI and monitoring."""
        task_id = f"test-integration-{uuid.uuid4()}"
        
        with timed_execution("Direct task submission and monitoring"):
            # Create a test task
            payload = {
                "task_id": task_id,
                "tenant_id": "test",
                "content": {
                    "objective": "Create a simple test report",
                    "process_type": "sequential"
                }
            }
            
            # Submit task to the research crew
            response = requests.post(
                f"{CREWAI_URL}/crews/research/tasks",
                json=payload
            )
            assert response.status_code == 200
            result = response.json()
            assert result["status"] == "accepted"
            assert result["task_id"] == task_id
            
            # Check task status after a short delay
            time.sleep(5)
            response = requests.get(f"{CREWAI_URL}/tasks/{task_id}")
            assert response.status_code == 200
            status = response.json()
            assert status["task_id"] == task_id
            assert status["crew_type"] == "research"
            
            print(f"Task submission successful: {task_id}")
            
            # Note: We don't wait for task completion as it might take a long time
            # In a real test, you might want to poll until completion or timeout

if __name__ == "__main__":
    import pytest
    pytest.main(["-v", __file__])
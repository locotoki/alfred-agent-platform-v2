"""E2E regression tests for platform stability."""

import json
import time

import pytest


class TestDataFlow:
    """Test data flow through the platform."""

    @pytest.mark.e2e
    @pytest.mark.regression
    def test_agent_orchestration_flow(self, http_client, alfred_base_url, wait_for_services):
        """Test complete agent orchestration flow."""
        # Create a test request
        request_data = {
            "message": "Test financial query",
            "agent_type": "financial_tax",
            "user_id": "test_user_001",
        }

        # Submit request to Alfred Core
        response = http_client.post(f"{alfred_base_url}/api/v1/agent/query", json=request_data)
        assert response.status_code in [200, 201]

        # Get request ID
        result = response.json()
        request_id = result.get("request_id")
        assert request_id is not None

        # Poll for completion
        max_attempts = 30
        for attempt in range(max_attempts):
            status_response = http_client.get(f"{alfred_base_url}/api/v1/agent/status/{request_id}")
            if status_response.status_code == 200:
                status = status_response.json()
                if status.get("status") in ["completed", "failed"]:
                    break
            time.sleep(1)

        # Verify completion
        assert status.get("status") == "completed"
        assert status.get("result") is not None


class TestPersistence:
    """Test data persistence across services."""

    @pytest.mark.e2e
    @pytest.mark.regression
    def test_database_persistence(self, http_client, alfred_base_url, wait_for_services):
        """Test database write and read operations."""
        # Create test data
        test_data = {
            "key": f"test_key_{int(time.time())}",
            "value": "test_value",
            "metadata": {"test": True},
        }

        # Write data
        write_response = http_client.post(f"{alfred_base_url}/api/v1/data/store", json=test_data)
        assert write_response.status_code in [200, 201]

        # Read data back
        read_response = http_client.get(
            f"{alfred_base_url}/api/v1/data/retrieve/{test_data['key']}"
        )
        assert read_response.status_code == 200

        # Verify data integrity
        retrieved = read_response.json()
        assert retrieved["value"] == test_data["value"]
        assert retrieved["metadata"]["test"] is True


class TestErrorHandling:
    """Test error handling and recovery."""

    @pytest.mark.e2e
    @pytest.mark.regression
    def test_invalid_request_handling(self, http_client, alfred_base_url, wait_for_services):
        """Test handling of invalid requests."""
        # Send invalid request
        invalid_data = {
            "invalid_field": "test",
        }

        response = http_client.post(f"{alfred_base_url}/api/v1/agent/query", json=invalid_data)

        # Should return 400 Bad Request
        assert response.status_code == 400
        error = response.json()
        assert "error" in error or "message" in error

    @pytest.mark.e2e
    @pytest.mark.regression
    def test_rate_limiting(self, http_client, alfred_base_url, wait_for_services):
        """Test rate limiting functionality."""
        # Send multiple rapid requests
        responses = []
        for i in range(20):
            response = http_client.get(f"{alfred_base_url}/health")
            responses.append(response.status_code)

        # Should not all be rate limited
        assert responses.count(429) < 10  # Less than half rate limited


class TestMetricsCollection:
    """Test metrics collection and reporting."""

    @pytest.mark.e2e
    @pytest.mark.regression
    def test_metrics_increment(self, http_client, alfred_base_url, wait_for_services):
        """Test that metrics are properly incremented."""
        # Get initial metrics
        metrics_before = http_client.get(f"{alfred_base_url}/metrics").text

        # Make some requests
        for _ in range(5):
            http_client.get(f"{alfred_base_url}/health")

        # Get metrics after
        time.sleep(1)  # Allow metrics to update
        metrics_after = http_client.get(f"{alfred_base_url}/metrics").text

        # Verify metrics increased
        assert metrics_after != metrics_before
        assert "alfred_health_check_total" in metrics_after

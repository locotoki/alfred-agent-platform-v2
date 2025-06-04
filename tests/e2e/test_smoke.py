import pytest

@pytest.mark.skip(reason="flaky after 13-svc refactor – see #642")
"""E2E smoke tests for core services."""

import pytest


class TestCoreServices:
    """Test core service health endpoints."""

    @pytest.mark.e2e
    def test_alfred_core_health(self, http_client, alfred_base_url, wait_for_services):
        """Test Alfred Core health endpoint."""
        response = http_client.get(f"{alfred_base_url}/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"

    @pytest.mark.e2e
    def test_ui_chat_health(self, http_client, wait_for_services):
        """Test UI Chat health endpoint."""
        response = http_client.get("http://localhost:3001/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"

    @pytest.mark.e2e
    def test_agent_orchestrator_health(self, http_client, wait_for_services):
        """Test Agent Orchestrator health endpoint."""
        response = http_client.get("http://localhost:8012/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"

    @pytest.mark.e2e
    def test_model_registry_health(self, http_client, wait_for_services):
        """Test Model Registry health endpoint."""
        response = http_client.get("http://localhost:8007/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"

    @pytest.mark.e2e
    def test_database_connectivity(self, http_client, alfred_base_url, wait_for_services):
        """Test database connectivity through Alfred Core."""
        response = http_client.get(f"{alfred_base_url}/health/db")
        assert response.status_code == 200
        data = response.json()
        assert data["postgres"]["status"] == "connected"
        assert data["redis"]["status"] == "connected"


class TestMetricsEndpoints:
    """Test metrics endpoints."""

    @pytest.mark.e2e
    def test_prometheus_metrics(self, http_client, wait_for_services):
        """Test Prometheus metrics endpoints."""
        services = [
            ("alfred-core", 8011),
            ("agent-orchestrator", 8012),
            ("model-registry", 8007),
        ]

        for service, port in services:
            response = http_client.get(f"http://localhost:{port}/metrics")
            assert response.status_code == 200
            assert "process_virtual_memory_bytes" in response.text
            assert "alfred_" in response.text  # Custom metrics


class TestSlackIntegration:
    """Test Slack integration."""

    @pytest.mark.e2e
    @pytest.mark.skipif(
        not pytest.config.getoption("--slack-tests"), reason="Slack tests disabled by default"
    )
    def test_slack_webhook(self, http_client, slack_webhook_url):
        """Test Slack webhook connectivity."""
        if not slack_webhook_url:
            pytest.skip("No Slack webhook URL configured")

        payload = {
            "text": "E2E test message",
            "channel": "#test-alerts",
        }
        response = http_client.post(slack_webhook_url, json=payload)
        assert response.status_code == 200

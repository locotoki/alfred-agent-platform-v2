"""Test health endpoints for Slack adapter."""

import pytest
from fastapi.testclient import TestClient

from alfred.adapters.slack.webhook import app


class TestHealthEndpoints:
    """Test health check endpoints."""

    def setup_method(self):
        """Set up test client."""
        self.client = TestClient(app)

    def test_health_endpoint(self):
        """Test /health endpoint returns 200 OK."""
        response = self.client.get("/health")
        assert response.status_code == 200

        data = response.json()
        assert data["status"] == "healthy"
        assert data["service"] == "alfred-slack-adapter"

    def test_healthz_endpoint(self):
        """Test /healthz endpoint returns 200 OK."""
        response = self.client.get("/healthz")
        assert response.status_code == 200

        data = response.json()
        assert data["status"] == "ok"
        assert data["service"] == "alfred-slack-adapter"
        assert "version" in data

    def test_health_endpoint_method_not_allowed(self):
        """Test health endpoint with POST returns 405."""
        response = self.client.post("/health")
        assert response.status_code == 405

    def test_healthz_endpoint_method_not_allowed(self):
        """Test healthz endpoint with POST returns 405."""
        response = self.client.post("/healthz")
        assert response.status_code == 405

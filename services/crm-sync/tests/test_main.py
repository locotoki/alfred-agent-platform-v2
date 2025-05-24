"""Tests for CRM sync service."""
from datetime import datetime, timezone
from unittest.mock import AsyncMock, Mock, patch

from app.main import app
from fastapi.testclient import TestClient

client = TestClient(app)


def test_health():
    """Test health check endpoint."""
    response = client.get("/healthz")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "ts" in data


@patch("app.main.hubspot")
def test_sync_success(mock_hubspot):
    """Test successful contact sync."""
    # Mock successful HubSpot response
    mock_resp = Mock()
    mock_resp.status_code = 200
    mock_resp.parsed = {"id": "123", "email": "test@example.com"}

    mock_hubspot.contacts.create_contact_async = AsyncMock(return_value=mock_resp)

    event = {
        "email": "test@example.com",
        "source": "web",
        "timestamp": datetime.now(tz=timezone.utc).isoformat(),
        "payload": {"firstName": "Test", "lastName": "User"},
    }

    response = client.post("/sync", json=event)
    assert response.status_code == 200
    assert response.json() == {"id": "123", "email": "test@example.com"}


@patch("app.main.hubspot")
def test_sync_upstream_error(mock_hubspot):
    """Test handling of upstream HubSpot error."""
    # Mock HubSpot error
    mock_resp = Mock()
    mock_resp.status_code = 500

    mock_hubspot.contacts.create_contact_async = AsyncMock(return_value=mock_resp)

    event = {
        "email": "test@example.com",
        "source": "web",
        "timestamp": datetime.now(tz=timezone.utc).isoformat(),
    }

    response = client.post("/sync", json=event)
    assert response.status_code == 502
    assert "Upstream HubSpot-mock error" in response.json()["detail"]

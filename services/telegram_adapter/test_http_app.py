"""Test script for Telegram adapter."""

from fastapi.testclient import TestClient

# Import the FastAPI app and metrics counter
from services.telegram_adapter.http_app import app, telegram_events_total


def test_handshake_returns_challenge():
    client = TestClient(app)
    challenge = "test_challenge"
    response = client.get(f"/telegram/webhook?challenge={challenge}")
    assert response.status_code == 200
    assert response.json() == challenge


def test_signature_pass(monkeypatch):
    client = TestClient(app)
    # Set environment variable for secret token
    monkeypatch.setenv("TELEGRAM_BOT_API_SECRET_TOKEN", "valid-token")
    response = client.post(
        "/telegram/webhook",
        json={"mock": "data"},
        headers={"X-Telegram-Bot-Api-Secret-Token": "valid-token"},
    )
    assert response.status_code == 200


def test_signature_fail():
    client = TestClient(app)
    response = client.post(
        "/telegram/webhook",
        json={"mock": "data"},
        headers={"X-Telegram-Bot-Api-Secret-Token": "invalid-token"},
    )
    assert response.status_code == 401
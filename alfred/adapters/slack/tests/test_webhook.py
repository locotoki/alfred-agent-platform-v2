"""Tests for Slack webhook with HMAC verification."""

import hashlib
import hmac
import json
import time
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient

from alfred.adapters.slack.webhook import SlackVerifier, app, slack_events_total


class TestSlackVerifier:
    """Test Slack signature verification."""

    @pytest.fixture
    def verifier(self):
        return SlackVerifier("test-secret")

    def test_valid_signature(self, verifier):
        """Test verification with valid signature."""
        timestamp = str(int(time.time()))
        body = b'{"test": "data"}'

        # Create valid signature
        sig_basestring = f"v0:{timestamp}:".encode() + body
        expected_sig = "v0=" + hmac.new(b"test-secret", sig_basestring, hashlib.sha256).hexdigest()

        assert verifier.verify_signature(timestamp, body, expected_sig) is True

    def test_invalid_signature(self, verifier):
        """Test verification with invalid signature."""
        timestamp = str(int(time.time()))
        body = b'{"test": "data"}'
        invalid_sig = "v0=invalid_signature"

        assert verifier.verify_signature(timestamp, body, invalid_sig) is False

    def test_old_timestamp(self, verifier):
        """Test verification with old timestamp."""
        # Timestamp from 10 minutes ago
        old_timestamp = str(int(time.time()) - 600)
        body = b'{"test": "data"}'

        # Even with valid signature, should fail due to old timestamp
        sig_basestring = f"v0:{old_timestamp}:".encode() + body
        valid_sig = "v0=" + hmac.new(b"test-secret", sig_basestring, hashlib.sha256).hexdigest()

        assert verifier.verify_signature(old_timestamp, body, valid_sig) is False

    def test_invalid_timestamp_format(self, verifier):
        """Test verification with invalid timestamp format."""
        invalid_timestamp = "not-a-number"
        body = b'{"test": "data"}'
        sig = "v0=some_signature"

        assert verifier.verify_signature(invalid_timestamp, body, sig) is False


class TestSlackWebhook:
    """Test Slack webhook endpoints."""

    @pytest.fixture
    def client(self):
        return TestClient(app)

    @pytest.fixture
    def valid_headers(self):
        """Generate valid Slack headers."""
        timestamp = str(int(time.time()))
        body = json.dumps({"test": "data"})

        # Create valid signature with test secret
        sig_basestring = f"v0:{timestamp}:".encode() + body.encode()
        signature = "v0=" + hmac.new(b"test-secret", sig_basestring, hashlib.sha256).hexdigest()

        return {
            "X-Slack-Request-Timestamp": timestamp,
            "X-Slack-Signature": signature,
            "Content-Type": "application/json",
        }

    def test_health_endpoint(self, client):
        """Test health check endpoint."""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"

    def test_root_endpoint(self, client):
        """Test root endpoint."""
        response = client.get("/")
        assert response.status_code == 200
        assert "Alfred Slack Adapter" in response.json()["service"]

    @patch("alfred.adapters.slack.webhook.verifier")
    def test_url_verification_challenge(self, mock_verifier, client):
        """Test URL verification challenge response."""
        mock_verifier.verify_signature.return_value = True

        challenge_data = {"type": "url_verification", "challenge": "test-challenge-string"}

        response = client.post(
            "/slack/events",
            json=challenge_data,
            headers={
                "X-Slack-Request-Timestamp": str(int(time.time())),
                "X-Slack-Signature": "v0=valid",
                "Content-Type": "application/json",
            },
        )

        assert response.status_code == 200
        assert response.json()["challenge"] == "test-challenge-string"

    @patch("alfred.adapters.slack.webhook.verifier")
    def test_slash_command_ping(self, mock_verifier, client):
        """Test /alfred ping slash command."""
        mock_verifier.verify_signature.return_value = True

        form_data = "command=/alfred&text=ping"

        response = client.post(
            "/slack/events",
            data=form_data,
            headers={
                "X-Slack-Request-Timestamp": str(int(time.time())),
                "X-Slack-Signature": "v0=valid",
                "Content-Type": "application/x-www-form-urlencoded",
            },
        )

        assert response.status_code == 200
        assert response.json()["text"] == "pong"
        assert response.json()["response_type"] == "in_channel"

    @patch("alfred.adapters.slack.webhook.verifier")
    def test_slash_command_other(self, mock_verifier, client):
        """Test /alfred with other text."""
        mock_verifier.verify_signature.return_value = True

        form_data = "command=/alfred&text=help"

        response = client.post(
            "/slack/events",
            data=form_data,
            headers={
                "X-Slack-Request-Timestamp": str(int(time.time())),
                "X-Slack-Signature": "v0=valid",
                "Content-Type": "application/x-www-form-urlencoded",
            },
        )

        assert response.status_code == 200
        assert "Received command: help" in response.json()["text"]
        assert response.json()["response_type"] == "ephemeral"

    @patch("alfred.adapters.slack.webhook.verifier")
    def test_invalid_signature(self, mock_verifier, client):
        """Test request with invalid signature."""
        mock_verifier.verify_signature.return_value = False

        response = client.post(
            "/slack/events",
            json={"test": "data"},
            headers={
                "X-Slack-Request-Timestamp": str(int(time.time())),
                "X-Slack-Signature": "v0=invalid",
                "Content-Type": "application/json",
            },
        )

        assert response.status_code == 401
        assert "Invalid signature" in response.json()["detail"]

    def test_missing_signature_headers(self, client):
        """Test request without signature headers."""
        with patch("alfred.adapters.slack.webhook.verifier") as mock_verifier:
            mock_verifier.verify_signature.return_value = True

            response = client.post(
                "/slack/events", json={"test": "data"}, headers={"Content-Type": "application/json"}
            )

            assert response.status_code == 401
            assert "Missing signature headers" in response.json()["detail"]

    @patch("alfred.adapters.slack.webhook.verifier")
    def test_invalid_json(self, mock_verifier, client):
        """Test request with invalid JSON."""
        mock_verifier.verify_signature.return_value = True

        response = client.post(
            "/slack/events",
            data="invalid json",
            headers={
                "X-Slack-Request-Timestamp": str(int(time.time())),
                "X-Slack-Signature": "v0=valid",
                "Content-Type": "application/json",
            },
        )

        assert response.status_code == 400
        assert "Invalid JSON" in response.json()["detail"]

    @patch("alfred.adapters.slack.webhook.verifier")
    def test_regular_event(self, mock_verifier, client):
        """Test regular Slack event."""
        mock_verifier.verify_signature.return_value = True

        event_data = {
            "type": "event_callback",
            "event": {"type": "message", "text": "Hello Alfred"},
        }

        response = client.post(
            "/slack/events",
            json=event_data,
            headers={
                "X-Slack-Request-Timestamp": str(int(time.time())),
                "X-Slack-Signature": "v0=valid",
                "Content-Type": "application/json",
            },
        )

        assert response.status_code == 200
        assert response.json()["status"] == "ok"

    @patch("alfred.adapters.slack.webhook.verifier", None)
    def test_no_verifier(self, client):
        """Test behavior when verifier is not configured."""
        # Should still accept requests when verifier is None
        response = client.post(
            "/slack/events", json={"type": "test"}, headers={"Content-Type": "application/json"}
        )

        assert response.status_code == 200

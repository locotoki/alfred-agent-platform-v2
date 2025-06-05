"""Unit tests for alert dispatcher module"""

import os
from unittest.mock import Mock, patch

import pytest
import requests

from alfred.alerts.dispatcher import format_alert_for_slack, handle_alert, send_to_slack

# Mark all tests in this module with the alerts marker
pytestmark = pytest.mark.alerts


class TestHandleAlert:
    """Test suite for handle_alert function"""

    @patch("alfred.alerts.dispatcher.send_to_slack")
    @patch("alfred.alerts.dispatcher.format_alert_for_slack")
    def test_handle_alert_success(self, mock_format, mock_send):
        """Test successful alert handling"""
        # Mock environment variables
        with patch.dict(
            os.environ,
            {
                "SLACK_ALERT_WEBHOOK": "https://hooks.slack.com/test",
                "GIT_SHA": "abc123def456",
                "POD_UID": "pod-12345",
                "CHART_VERSION": "0.8.2",
            },
        ):
            # Mock format function
            mock_format.return_value = {"text": "Test alert"}

            # Test payload
            alert_json = {
                "alerts": [
                    {
                        "labels": {
                            "alertname": "TestAlert",
                            "severity": "critical",
                            "service": "test-service",
                        },
                        "annotations": {
                            "summary": "Test alert summary",
                        },
                    }
                ]
            }

            # Call function
            handle_alert(alert_json)

            # Verify calls
            mock_format.assert_called_once_with(
                alert=alert_json["alerts"][0],
                git_sha="abc123def456",
                pod_uid="pod-12345",
                chart_version="0.8.2",
            )
            mock_send.assert_called_once_with(
                "https://hooks.slack.com/test",
                {"text": "Test alert"},
            )

    def test_handle_alert_missing_webhook(self):
        """Test error when SLACK_ALERT_WEBHOOK is missing"""
        with patch.dict(os.environ, {}, clear=True):
            with pytest.raises(ValueError, match="SLACK_ALERT_WEBHOOK"):
                handle_alert({"alerts": [{}]})

    @patch("alfred.alerts.dispatcher.send_to_slack")
    def test_handle_alert_empty_alerts(self, mock_send):
        """Test handling of empty alerts array"""
        with patch.dict(
            os.environ,
            {
                "SLACK_ALERT_WEBHOOK": "https://hooks.slack.com/test",
            },
        ):
            handle_alert({"alerts": []})
            mock_send.assert_not_called()

    @patch(
        "alfred.alerts.dispatcher.send_to_slack", side_effect=Exception("Slack error")
    )
    @patch("alfred.alerts.dispatcher.format_alert_for_slack")
    def test_handle_alert_send_failure(self, mock_format, mock_send):
        """Test error handling when Slack send fails"""
        with patch.dict(
            os.environ,
            {
                "SLACK_ALERT_WEBHOOK": "https://hooks.slack.com/test",
            },
        ):
            mock_format.return_value = {"text": "Test"}

            with pytest.raises(Exception, match="Slack error"):
                handle_alert({"alerts": [{"labels": {}}]})


class TestFormatAlertForSlack:
    """Test suite for format_alert_for_slack function"""

    @pytest.mark.parametrize(
        "severity,expected_emoji,expected_color",
        [
            ("critical", "🚨", "#FF0000"),
            ("warning", "⚠️", "#FFA500"),
            ("info", "ℹ️", "#0000FF"),
            ("unknown", "ℹ️", "#808080"),  # Default case
        ],
    )
    def test_severity_formatting(self, severity, expected_emoji, expected_color):
        """Test proper severity-based formatting"""
        alert = {
            "labels": {
                "alertname": "TestAlert",
                "severity": severity,
                "service": "test-service",
                "runbook": "https://example.com/runbook.md",
            },
            "annotations": {
                "summary": "Test summary",
                "description": "Test description",
            },
            "status": "firing",
        }

        result = format_alert_for_slack(
            alert=alert,
            git_sha="abc123def456",
            pod_uid="pod-12345",
            chart_version="0.8.2",
        )

        # Check main text
        assert expected_emoji in result["text"]
        assert severity.upper() in result["text"]

        # Check attachment
        attachment = result["attachments"][0]
        assert attachment["color"] == expected_color
        assert attachment["title"] == "TestAlert"

        # Check all enrichment fields are present
        fields = {field["title"]: field["value"] for field in attachment["fields"]}
        assert fields["Service"] == "test-service"
        assert fields["Severity"] == severity.upper()
        assert fields["Pod UID"] == "pod-12345"
        assert fields["Chart Version"] == "0.8.2"
        assert fields["Git SHA"] == "abc123de"  # Should be truncated
        assert fields["Status"] == "firing"

        # Check runbook action
        assert attachment["actions"][0]["url"] == "https://example.com/runbook.md"

    def test_format_minimal_alert(self):
        """Test formatting with minimal alert data"""
        alert = {
            "labels": {},
            "annotations": {},
        }

        result = format_alert_for_slack(
            alert=alert,
            git_sha="unknown",
            pod_uid="unknown",
            chart_version="unknown",
        )

        assert "Unknown Alert" in result["text"]
        attachment = result["attachments"][0]
        assert attachment["title"] == "Unknown Alert"
        assert "actions" not in attachment  # No runbook

    def test_format_with_description(self):
        """Test that description is included when present"""
        alert = {
            "labels": {"alertname": "TestAlert"},
            "annotations": {
                "summary": "Test summary",
                "description": "Detailed description of the issue",
            },
        }

        result = format_alert_for_slack(
            alert=alert,
            git_sha="abc123",
            pod_uid="pod-123",
            chart_version="1.0.0",
        )

        # Find description field
        attachment = result["attachments"][0]
        description_field = None
        for field in attachment["fields"]:
            if field["title"] == "Description":
                description_field = field
                break

        assert description_field is not None
        assert description_field["value"] == "Detailed description of the issue"
        assert description_field["short"] is False


class TestSendToSlack:
    """Test suite for send_to_slack function"""

    @patch("alfred.alerts.dispatcher.requests.post")
    def test_send_success(self, mock_post):
        """Test successful Slack webhook call"""
        mock_response = Mock()
        mock_response.text = "ok"
        mock_response.raise_for_status = Mock()
        mock_post.return_value = mock_response

        message = {"text": "Test message"}
        send_to_slack("https://hooks.slack.com/test", message)

        mock_post.assert_called_once_with(
            "https://hooks.slack.com/test",
            json=message,
            headers={"Content-Type": "application/json"},
            timeout=10,
        )

    @patch("alfred.alerts.dispatcher.requests.post")
    def test_send_non_ok_response(self, mock_post):
        """Test error handling for non-ok Slack response"""
        mock_response = Mock()
        mock_response.text = "invalid_payload"
        mock_response.raise_for_status = Mock()
        mock_post.return_value = mock_response

        with pytest.raises(requests.RequestException, match="invalid_payload"):
            send_to_slack("https://hooks.slack.com/test", {"text": "Test"})

    @patch("alfred.alerts.dispatcher.requests.post")
    def test_send_http_error(self, mock_post):
        """Test error handling for HTTP errors"""
        mock_response = Mock()
        mock_response.raise_for_status.side_effect = requests.HTTPError("404 Not Found")
        mock_post.return_value = mock_response

        with pytest.raises(requests.HTTPError, match="404 Not Found"):
            send_to_slack("https://hooks.slack.com/test", {"text": "Test"})

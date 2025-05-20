"""Unit tests for the explain command handler."""

from unittest.mock import Mock, patch

from alfred.slack.diagnostics.explain_command import handle_explain_command


def test_handle_explain_command_success():.
    """Test successful explain command handling."""
    result = handle_explain_command("explain", "ALERT-123")

    assert result["response_type"] == "in_channel"
    assert "Alert Explanation for ALERT-123" in result["text"]
    assert len(result["attachments"]) == 1
    assert result["attachments"][0]["color"] == "good"
    assert "Explanation:" in result["attachments"][0]["text"]


@patch("alfred.slack.diagnostics.explain_command.ExplainerAgent")
def test_handle_explain_command_failure(mock_agent_cls):
    """Test explain command handling when agent fails."""
    mock_agent = Mock()
    mock_agent.explain_alert.return_value = {
        "success": False,
        "explanation": "Error: LLM not available",
    }
    mock_agent_cls.return_value = mock_agent

    result = handle_explain_command("explain", "ALERT-456")

    assert result["response_type"] == "ephemeral"
    assert "Failed to explain alert ALERT-456" in result["text"]
    assert "Error: LLM not available" in result["text"]

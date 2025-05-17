"""Slash command handler for alert explanations."""

import logging
from typing import Any, Dict

from alfred.alerts.explainer import ExplainerAgent

logger = logging.getLogger(__name__)


def handle_explain_command(command: str, alert_id: str) -> Dict[str, Any]:
    """Handle the /diag explain <alert-id> command.

    Args:
        command: The command string (should be "explain")
        alert_id: The alert ID to explain

    Returns:
        Dict containing the response for Slack
    """
    logger.info(f"Handling explain command for alert: {alert_id}")

    # In a real implementation, this would fetch the alert from storage
    # For now, we'll use a stub alert
    stub_alert = {
        "alert_name": f"Alert {alert_id}",
        "description": "High CPU usage detected",
        "value": "95%",
    }

    agent = ExplainerAgent()  # Stub mode by default
    result = agent.explain_alert(stub_alert)

    if result["success"]:
        return {
            "response_type": "in_channel",
            "text": f"Alert Explanation for {alert_id}",
            "attachments": [{"text": result["explanation"], "color": "good"}],
        }
    else:
        return {
            "response_type": "ephemeral",
            "text": f"Failed to explain alert {alert_id}: {result['explanation']}",
        }

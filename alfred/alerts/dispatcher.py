"""Alert dispatcher module for enriching and forwarding Prometheus alerts to Slack."""

import json
import os
import urllib.parse
from datetime import datetime
from typing import Any, Dict, Optional

import requests
import structlog

logger = structlog.get_logger(__name__)

# Severity emoji mapping
SEVERITY_EMOJI = {
    "critical": "🚨",
    "warning": "⚠️",
    "info": "ℹ️",
}

# Severity color mapping for Slack attachments
SEVERITY_COLOR = {
    "critical": "#FF0000",  # Red
    "warning": "#FFA500",  # Orange
    "info": "#0000FF",  # Blue
}


def handle_alert(alert_json: Dict[str, Any]) -> None:
    """
    Process incoming Prometheus alert and forward to Slack with enrichment.

    Args:
        alert_json: Alert payload from Alertmanager

    Raises:
        ValueError: If required environment variables are missing
        requests.RequestException: If Slack webhook call fails
    """
    # Validate required environment variables
    slack_webhook = os.getenv("SLACK_ALERT_WEBHOOK")
    if not slack_webhook:
        raise ValueError("SLACK_ALERT_WEBHOOK environment variable is required")

    # Extract enrichment data from environment
    git_sha = os.getenv("GIT_SHA", "unknown")
    pod_uid = os.getenv("POD_UID", "unknown")
    chart_version = os.getenv("CHART_VERSION", "unknown")

    # Extract alert details
    alerts = alert_json.get("alerts", [])

    if not alerts:
        logger.warning("No alerts found in payload", payload=alert_json)
        return

    # Process each alert
    for alert in alerts:
        try:
            slack_message = format_alert_for_slack(
                alert=alert,
                git_sha=git_sha,
                pod_uid=pod_uid,
                chart_version=chart_version,
            )

            send_to_slack(slack_webhook, slack_message)

            logger.info(
                "Alert sent to Slack",
                alert_name=alert.get("labels", {}).get("alertname"),
                severity=alert.get("labels", {}).get("severity"),
            )

        except Exception as e:
            logger.error(
                "Failed to send alert to Slack",
                error=str(e),
                alert=alert,
            )
            raise


def format_alert_for_slack(
    alert: Dict[str, Any],
    git_sha: str,
    pod_uid: str,
    chart_version: str,
) -> Dict[str, Any]:
    """
    Format Prometheus alert for Slack message.

    Args:
        alert: Individual alert from Alertmanager
        git_sha: Git commit SHA
        pod_uid: Kubernetes pod UID
        chart_version: Helm chart version

    Returns:
        Formatted Slack message payload
    """
    labels = alert.get("labels", {})
    annotations = alert.get("annotations", {})

    # Extract key fields
    alert_name = labels.get("alertname", "Unknown Alert")
    severity = labels.get("severity", "info").lower()
    service = labels.get("service", "unknown")
    runbook = labels.get("runbook", "")
    summary = annotations.get("summary", "No summary provided")
    description = annotations.get("description", "")

    # Get appropriate emoji and color
    emoji = SEVERITY_EMOJI.get(severity, "ℹ️")
    color = SEVERITY_COLOR.get(severity, "#808080")

    # Build Slack message
    text = f"{emoji} [{severity.upper()}] {alert_name}"

    # Create attachment with detailed information
    attachment = {
        "color": color,
        "title": alert_name,
        "text": summary,
        "fields": [
            {
                "title": "Service",
                "value": service,
                "short": True,
            },
            {
                "title": "Severity",
                "value": severity.upper(),
                "short": True,
            },
            {
                "title": "Pod UID",
                "value": pod_uid,
                "short": True,
            },
            {
                "title": "Chart Version",
                "value": chart_version,
                "short": True,
            },
            {
                "title": "Git SHA",
                "value": git_sha[:8] if len(git_sha) > 8 else git_sha,
                "short": True,
            },
            {
                "title": "Status",
                "value": alert.get("status", "unknown"),
                "short": True,
            },
        ],
        "footer": "Alfred Alert System",
        "ts": int(datetime.utcnow().timestamp()),
    }

    # Add description if provided
    if description:
        attachment["fields"].append(
            {
                "title": "Description",
                "value": description,
                "short": False,
            }
        )

    # Add runbook link if available
    if runbook:
        attachment["actions"] = [
            {
                "type": "button",
                "text": "View Runbook",
                "url": runbook,
            }
        ]

    return {
        "text": text,
        "attachments": [attachment],
    }


def send_to_slack(webhook_url: str, message: Dict[str, Any]) -> None:
    """
    Send formatted message to Slack webhook.

    Args:
        webhook_url: Slack webhook URL
        message: Formatted message payload

    Raises:
        requests.RequestException: If webhook call fails
    """
    response = requests.post(
        webhook_url,
        json=message,
        headers={"Content-Type": "application/json"},
        timeout=10,
    )

    response.raise_for_status()

    if response.text != "ok":
        raise requests.RequestException(f"Slack webhook returned: {response.text}")

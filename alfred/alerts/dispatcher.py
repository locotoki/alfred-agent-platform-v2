"""Alert dispatcher for Alfred.

This module handles the dispatching of alerts to different notification channels.
"""

import jsonLFimport osLFfrom typing import Any, DictLFLFimport requestsLFimport structlogLFLFlogger = structlog.get_logger(__name__)LF

def handle_alert(alert_data: Dict[str, Any]) -> None:
    """Handle incoming alert data and dispatch to appropriate channels.

    Args:
        alert_data: The alert data received from the alerting system.
    """
    alerts = alert_data.get("alerts", [])
    logger.info("Received alerts", count=len(alerts))

    # Get Slack webhook URL from environment
    slack_webhook = os.environ.get("SLACK_WEBHOOK_URL")
    if not slack_webhook:
        logger.warning("No Slack webhook URL configured, alerts will not be sent")
        return

    # Process each alert
    for alert in alerts:
        # Skip resolved alerts if configured to do so
        if (
            alert.get("status") == "resolved"
            and not os.environ.get("SEND_RESOLVED", "true").lower() == "true"
        ):
            logger.info(
                "Skipping resolved alert",
                alert_name=alert.get("labels", {}).get("alertname"),
            )
            continue

        # Check for alert grouping and snooze settings
        if is_alert_snoozed(alert):
            logger.info(
                "Alert is snoozed, skipping",
                alert_name=alert.get("labels", {}).get("alertname"),
            )
            continue

        try:
            # Extract alert details
            alertname = alert.get("labels", {}).get("alertname", "Unknown Alert")
            severity = alert.get("labels", {}).get("severity", "unknown")
            summary = alert.get("annotations", {}).get("summary", "No summary provided")
            description = alert.get("annotations", {}).get("description", "No description provided")

            # Extract Kubernetes metadata if available
            namespace = alert.get("labels", {}).get("namespace", "unknown")
            pod_name = alert.get("labels", {}).get("pod", "unknown")
            pod_uid = alert.get("labels", {}).get("pod_uid", "unknown")
            chart_version = alert.get("labels", {}).get("chart_version", "unknown")

            # Format message for Slack
            slack_message = format_slack_alert(
                alertname=alertname,
                severity=severity,
                summary=summary,
                description=description,
                namespace=namespace,
                pod_name=pod_name,
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
                error_type=type(e).__name__,
                alert=json.dumps(alert),
            )


def is_alert_snoozed(alert: Dict[str, Any]) -> bool:
    """Check if an alert is snoozed.

    Args:
        alert: The alert to check.

    Returns:
        True if the alert is snoozed, False otherwise.
    """
    # TODO: Implement alert snoozing via database
    return False


def format_slack_alert(
    alertname: str,
    severity: str,
    summary: str,
    description: str,
    namespace: str,
    pod_name: str,
    pod_uid: str,
    chart_version: str,
) -> Dict[str, Any]:
    """Format alert data for Slack notification.

    Args:
        alertname: The name of the alert.
        severity: The severity level.
        summary: A brief summary.
        description: A detailed description.
        namespace: The Kubernetes namespace.
        pod_name: The pod name.
        pod_uid: The pod UID.
        chart_version: The Helm chart version.

    Returns:
        A dictionary formatted for the Slack API.
    """
    # Set color based on severity
    color = {
        "critical": "#FF0000",  # Red
        "warning": "#FFA500",  # Orange
        "info": "#0000FF",  # Blue
    }.get(
        severity.lower(), "#808080"
    )  # Gray default

    # Common fields for any alert
    fields = [
        {
            "title": "Severity",
            "value": severity.upper(),
            "short": True,
        },
        {
            "title": "Namespace",
            "value": namespace,
            "short": True,
        },
    ]

    # Add pod info if available
    if pod_name != "unknown":
        fields.append(
            {
                "title": "Pod",
                "value": pod_name,
                "short": True,
            }
        )

    # Add chart version if available
    if chart_version != "unknown":
        fields.append(
            {
                "title": "Chart Version",
                "value": chart_version,
                "short": True,
            }
        )

    return {
        "attachments": [
            {
                "color": color,
                "title": f"Alert: {alertname}",
                "text": description,
                "fields": fields,
                "footer": "Alfred Alert System",
            }
        ]
    }


def send_to_slack(webhook_url: str, message: Dict[str, Any]) -> None:
    """Send a message to a Slack webhook.

    Args:
        webhook_url: The Slack webhook URL.
        message: The message to send.
    """
    try:
        response = requests.post(
            webhook_url,
            json=message,
            headers={"Content-Type": "application/json"},
            timeout=10,
        )
        response.raise_for_status()
    except requests.RequestException as e:
        logger.error(
            "Failed to send message to Slack",
            error=str(e),
            error_type=type(e).__name__,
        )
        raise

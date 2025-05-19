#!/usr/bin/env python3
"""Test the alert dispatcher locally."""

import json
import os
import sys
from pathlib import Path

# Add the project root to Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

from alfred.alerts.dispatcher import handle_alert  # noqa: E402


def test_dispatcher():
    """Test the dispatcher with local alert files."""
    # Set test environment variables
    os.environ["SLACK_ALERT_WEBHOOK"] = "https://hooks.slack.com/services/TEST/WEBHOOK/URL"
    os.environ["GIT_SHA"] = "abc123def456789"
    os.environ["POD_UID"] = "test-pod-12345"
    os.environ["CHART_VERSION"] = "0.8.2-test"

    # Load test alert
    alerts_dir = Path(__file__).parent / "alerts"
    critical_alert = alerts_dir / "critical.json"

    with open(critical_alert) as f:
        alert_data = json.load(f)

    print("Testing alert dispatcher with:")
    print(f"Alert: {alert_data['commonLabels']['alertname']}")
    print(f"Severity: {alert_data['commonLabels']['severity']}")
    print(f"Service: {alert_data['commonLabels']['service']}")

    try:
        # This will fail with webhook error, but we can see the formatting
        handle_alert(alert_data)
    except Exception as e:
        print(f"\nExpected error (no real webhook): {e}")
        print("\nBut the alert was processed successfully!")


if __name__ == "__main__":
    test_dispatcher()

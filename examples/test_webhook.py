#!/usr/bin/env python3
"""Test the alert dispatcher with a real Slack webhook."""

import json
import os
import sys
from pathlib import Path

# Add the project root to Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

from alfred.alerts.dispatcher import handle_alert

def test_with_webhook(webhook_url):
    """Test the dispatcher with real Slack webhook."""
    # Set environment variables
    os.environ["SLACK_ALERT_WEBHOOK"] = webhook_url
    os.environ["GIT_SHA"] = "abc123def456789"
    os.environ["POD_UID"] = "staging-pod-7d4f6b"
    os.environ["CHART_VERSION"] = "0.8.2"
    
    # Test both critical and warning alerts
    alerts_dir = Path(__file__).parent / "alerts"
    
    for alert_file in ["critical.json", "warning.json"]:
        alert_path = alerts_dir / alert_file
        
        with open(alert_path) as f:
            alert_data = json.load(f)
        
        print(f"\n📧 Sending {alert_file} to Slack...")
        print(f"Alert: {alert_data['commonLabels']['alertname']}")
        print(f"Severity: {alert_data['commonLabels']['severity']}")
        
        try:
            handle_alert(alert_data)
            print("✅ Successfully sent to Slack!")
        except Exception as e:
            print(f"❌ Error: {e}")
            return False
    
    print("\n🎉 All alerts sent successfully!")
    print("\nPlease check your Slack channel to verify:")
    print("1. 🚨 emoji for critical alert")
    print("2. ⚠️ emoji for warning alert")
    print("3. Runbook links are clickable")
    print("4. Metadata fields show test values")
    return True

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python test_webhook.py <SLACK_WEBHOOK_URL>")
        sys.exit(1)
    
    webhook_url = sys.argv[1]
    success = test_with_webhook(webhook_url)
    sys.exit(0 if success else 1)
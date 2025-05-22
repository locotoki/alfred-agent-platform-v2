#!/usr/bin/env python3
"""
Slack CVE Alert - DA-008.

Reads vulnerability report and posts HIGH/CRITICAL CVEs to Slack #sec-alerts channel.
Only alerts for CVEs younger than 30 days or without available fixes.

Usage: python scripts/slack_cve_alert.py
Environment: SLACK_CVE_WEBHOOK (optional, fails silently if missing)
"""
import csv
import json
import os
import sys
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import Dict, List
from urllib.error import URLError


def read_vulnerability_report(report_path: Path) -> List[Dict[str, str]]:
    """Read vulnerability report CSV and return list of vulnerabilities."""
    vulnerabilities = []
    if not report_path.exists():
        print(f"Warning: Vulnerability report not found at {report_path}", file=sys.stderr)
        return vulnerabilities

    try:
        with open(report_path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row.get("package"):  # Skip empty rows
                    vulnerabilities.append(row)
    except Exception as e:
        print(f"Error reading vulnerability report: {e}", file=sys.stderr)
        return []

    return vulnerabilities


def get_cve_age_days(vuln_id: str) -> int:
    """Estimate CVE age in days based on CVE ID year."""
    if vuln_id.startswith("CVE-"):
        try:
            year_str = vuln_id.split("-")[1]
            cve_year = int(year_str)
            estimated_date = datetime(cve_year, 1, 1)
            return (datetime.now() - estimated_date).days
        except (IndexError, ValueError):
            pass
    return 0  # Unknown age, treat as new


def filter_alertable_vulnerabilities(
    vulnerabilities: List[Dict[str, str]], max_age_days: int = 30
) -> List[Dict[str, str]]:
    """Filter vulnerabilities that should trigger Slack alerts."""
    alertable = []

    for vuln in vulnerabilities:
        severity = vuln.get("severity", "unknown").lower()

        # Only alert for critical/high severity
        if severity not in ["critical", "high"]:
            continue

        vuln_id = vuln.get("vuln_id", "")
        fixed_version = vuln.get("fixed_version", "")

        # Alert if no fix available OR if CVE is young
        age_days = get_cve_age_days(vuln_id)
        no_fix = not fixed_version or fixed_version in ["", "unknown"]
        is_young = age_days <= max_age_days

        if no_fix or is_young:
            alertable.append(vuln)

    return alertable


def format_slack_message(vulnerabilities: List[Dict[str, str]]) -> Dict[str, any]:
    """Format vulnerabilities into Slack message payload."""
    if not vulnerabilities:
        return {
            "text": "🛡️ Security Scan Complete - No critical/high vulnerabilities requiring immediate attention",
            "blocks": [
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "🛡️ *Security Scan Complete*\n\nNo critical or high severity vulnerabilities requiring immediate attention found.",
                    },
                }
            ],
        }

    # Group by severity
    critical_vulns = [v for v in vulnerabilities if v.get("severity", "").lower() == "critical"]
    high_vulns = [v for v in vulnerabilities if v.get("severity", "").lower() == "high"]

    total_count = len(vulnerabilities)
    critical_count = len(critical_vulns)
    high_count = len(high_vulns)

    # Build message
    header = f"🚨 *Security Alert: {total_count} HIGH/CRITICAL CVEs*"
    if critical_count > 0:
        header += f"\n🔴 {critical_count} CRITICAL"
    if high_count > 0:
        header += f"\n🟠 {high_count} HIGH"

    blocks = [{"type": "section", "text": {"type": "mrkdwn", "text": header}}, {"type": "divider"}]

    # Add vulnerability details (limit to first 10 to avoid message size limits)
    displayed_vulns = vulnerabilities[:10]
    for vuln in displayed_vulns:
        package = vuln.get("package", "unknown")
        vuln_id = vuln.get("vuln_id", "unknown")
        severity = vuln.get("severity", "unknown").upper()
        fixed_version = vuln.get("fixed_version", "")

        severity_emoji = "🔴" if severity == "CRITICAL" else "🟠"
        fix_info = (
            f"Fix: {fixed_version}"
            if fixed_version and fixed_version != "unknown"
            else "❌ No fix available"
        )

        blocks.append(
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"{severity_emoji} *{package}*: {vuln_id} ({severity})\n{fix_info}",
                },
            }
        )

    if len(vulnerabilities) > 10:
        blocks.append(
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"... and {len(vulnerabilities) - 10} more vulnerabilities",
                },
            }
        )

    blocks.append({"type": "divider"})
    blocks.append(
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "📋 Review full report: `metrics/vulnerability_report.csv`\n🔧 Update dependencies to resolve vulnerabilities",
            },
        }
    )

    return {"text": f"Security Alert: {total_count} HIGH/CRITICAL CVEs found", "blocks": blocks}


def send_slack_alert(message: Dict[str, any], webhook_url: str) -> bool:
    """Send alert to Slack webhook and return success status."""
    try:
        payload = json.dumps(message).encode("utf-8")
        req = urllib.request.Request(
            webhook_url, data=payload, headers={"Content-Type": "application/json"}
        )

        with urllib.request.urlopen(req, timeout=10) as response:
            if response.status == 200:
                print("✅ Slack alert sent successfully")
                return True
            else:
                print(f"❌ Slack webhook returned status {response.status}", file=sys.stderr)
                return False

    except URLError as e:
        print(f"❌ Failed to send Slack alert: {e}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"❌ Error sending Slack alert: {e}", file=sys.stderr)
        return False


def main():
    """Generate and send Slack CVE alerts."""
    repo_root = Path(__file__).parent.parent
    report_path = repo_root / "metrics" / "vulnerability_report.csv"

    # Read vulnerability report
    vulnerabilities = read_vulnerability_report(report_path)
    print(f"📊 Found {len(vulnerabilities)} total vulnerabilities")

    # Filter for alertable CVEs
    alertable_vulns = filter_alertable_vulnerabilities(vulnerabilities)
    print(f"🚨 Found {len(alertable_vulns)} alertable HIGH/CRITICAL CVEs")

    # Format Slack message
    message = format_slack_message(alertable_vulns)

    # Get webhook URL from environment
    webhook_url = os.getenv("SLACK_CVE_WEBHOOK")
    if not webhook_url:
        print("ℹ️  SLACK_CVE_WEBHOOK not set, skipping Slack notification")
        print("📱 Alert message preview:")
        print(json.dumps(message, indent=2))
        return

    # Send to Slack
    success = send_slack_alert(message, webhook_url)
    if success:
        print(f"📤 Notified #sec-alerts of {len(alertable_vulns)} alertable vulnerabilities")
    else:
        print("❌ Failed to send Slack notification")


if __name__ == "__main__":
    main()

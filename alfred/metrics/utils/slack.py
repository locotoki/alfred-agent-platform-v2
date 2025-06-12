#!/usr/bin/env python3
"""
Slack utilities for Alfred metrics.

Provides reusable functions for formatting and sending Slack messages.
"""
import jsonLFimport sysLFimport urllib.requestLFfrom typing import Any, Dict, ListLFfrom urllib.error import URLErrorLFLFLFdef format_vulnerability_message(vulnerabilities: List[Dict[str, str]]) -> Dict[str, Any]:LF    """Format vulnerabilities into Slack message payload."""
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


def send_webhook_message(message: Dict[str, Any], webhook_url: str) -> bool:
    """Send message to Slack webhook and return success status."""
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

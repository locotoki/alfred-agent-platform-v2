#!/usr/bin/env python3
"""
CI Vulnerability Gate - DA-007.

Parses vulnerability report CSV and fails CI if critical or high severity
vulnerabilities are found in dependencies.

Usage: python scripts/ci_vuln_gate.py
Exit codes: 0 = no critical/high CVEs, 1 = blocking vulnerabilities found
"""
import csv
import sys
from pathlib import Path
from typing import Dict, List


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
        sys.exit(1)

    return vulnerabilities


def analyze_vulnerabilities(vulnerabilities: List[Dict[str, str]]) -> Dict[str, int]:
    """Analyze vulnerabilities by severity and return counts."""
    severity_counts = {"critical": 0, "high": 0, "medium": 0, "low": 0, "unknown": 0}

    for vuln in vulnerabilities:
        severity = vuln.get("severity", "unknown").lower()
        if severity in severity_counts:
            severity_counts[severity] += 1
        else:
            severity_counts["unknown"] += 1

    return severity_counts


def print_vulnerability_summary(severity_counts: Dict[str, int], total_count: int):
    """Print a formatted vulnerability summary."""
    print("🔍 Vulnerability Scan Results")
    print("=" * 40)
    print(f"Total vulnerabilities found: {total_count}")
    print()

    if total_count == 0:
        print("✅ No vulnerabilities detected in dependencies")
        return

    print("Breakdown by severity:")
    for severity, count in severity_counts.items():
        if count > 0:
            emoji = {
                "critical": "🔴",
                "high": "🟠",
                "medium": "🟡",
                "low": "🟢",
                "unknown": "⚪",
            }.get(severity, "⚪")
            print(f"  {emoji} {severity.upper()}: {count}")


def main():
    """Run the CI vulnerability gate check."""
    repo_root = Path(__file__).parent.parent
    report_path = repo_root / "metrics" / "vulnerability_report.csv"

    # Read vulnerability report
    vulnerabilities = read_vulnerability_report(report_path)
    total_count = len(vulnerabilities)

    # Analyze by severity
    severity_counts = analyze_vulnerabilities(vulnerabilities)

    # Print summary
    print_vulnerability_summary(severity_counts, total_count)

    # Check for blocking vulnerabilities (critical or high)
    blocking_count = severity_counts["critical"] + severity_counts["high"]

    if blocking_count > 0:
        print()
        print("❌ CI GATE FAILURE")
        print(f"Found {blocking_count} critical/high severity vulnerabilities")
        print("🛡️  Action required: Update vulnerable dependencies before merging")
        print()

        # Show detailed info for blocking vulnerabilities
        print("Blocking vulnerabilities:")
        for vuln in vulnerabilities:
            severity = vuln.get("severity", "unknown").lower()
            if severity in ["critical", "high"]:
                package = vuln.get("package", "unknown")
                vuln_id = vuln.get("vuln_id", "unknown")
                fixed_version = vuln.get("fixed_version", "unknown")
                print(f"  • {package}: {vuln_id} ({severity.upper()}) - fix: {fixed_version}")

        sys.exit(1)

    print()
    print("✅ CI GATE PASSED")
    print("No critical or high severity vulnerabilities found")
    sys.exit(0)


if __name__ == "__main__":
    main()

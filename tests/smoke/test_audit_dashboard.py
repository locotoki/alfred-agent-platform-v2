"""Smoke tests for audit dashboard generation system - DA-006."""

import subprocess
from pathlib import Path


def test_audit_dashboard_generator_exists():
    """Test that the audit dashboard generator script exists."""
    repo_root = Path(__file__).parent.parent.parent
    assert (repo_root / "scripts" / "gen_audit_dashboard.py").exists()


def test_audit_dashboard_can_be_generated():
    """Test that the audit dashboard can be generated without errors."""
    repo_root = Path(__file__).parent.parent.parent
    dashboard_path = repo_root / "docs" / "audit" / "dashboard.md"

    if not dashboard_path.exists():
        subprocess.run(
            ["python", "scripts/gen_audit_dashboard.py"],
            cwd=repo_root,
            check=True,
            capture_output=True,
        )

    assert dashboard_path.exists()


def test_audit_dashboard_contains_badges():
    """Test that the audit dashboard contains the required workflow badges."""
    repo_root = Path(__file__).parent.parent.parent
    dashboard_path = repo_root / "docs" / "audit" / "dashboard.md"
    assert dashboard_path.exists()

    with open(dashboard_path, "r", encoding="utf-8") as f:
        content = f.read()

    expected_badges = [
        "deps-inventory-cron.yml/badge.svg",
        "vuln-scan-cron.yml/badge.svg",
        "license-scan-cron.yml/badge.svg",
    ]
    for badge in expected_badges:
        assert badge in content


def test_audit_dashboard_format():
    """Test that the audit dashboard has proper markdown format."""
    repo_root = Path(__file__).parent.parent.parent
    dashboard_path = repo_root / "docs" / "audit" / "dashboard.md"
    assert dashboard_path.exists()

    with open(dashboard_path, "r", encoding="utf-8") as f:
        content = f.read()

    required_sections = [
        "# 📊 Dependency Audit Dashboard",
        "## 🛡️ Status Badges",
        "## 📈 Summary Statistics",
        "## 📋 Data Sources",
    ]
    for section in required_sections:
        assert section in content


def test_makefile_audit_dashboard_target():
    """Test that the Makefile has an audit-dashboard target."""
    repo_root = Path(__file__).parent.parent.parent
    with open(repo_root / "Makefile", "r", encoding="utf-8") as f:
        content = f.read()
    assert "audit-dashboard:" in content and "gen_audit_dashboard.py" in content


def test_workflow_file_exists():
    """Test that the audit dashboard cron workflow exists."""
    repo_root = Path(__file__).parent.parent.parent
    workflow_path = repo_root / ".github" / "workflows" / "audit-dashboard-cron.yml"
    assert workflow_path.exists()

    with open(workflow_path, "r", encoding="utf-8") as f:
        content = f.read()

    assert "name: Audit Dashboard Update" in content
    assert "cron: '25 8 * * 1'" in content
    assert "make audit-dashboard" in content


def test_dashboard_contains_statistics():
    """Test that the dashboard contains basic statistics sections."""
    repo_root = Path(__file__).parent.parent.parent
    with open(repo_root / "docs" / "audit" / "dashboard.md", "r", encoding="utf-8") as f:
        content = f.read()

    stats_sections = [
        "### Dependencies",
        "### Security",
        "### License Compliance",
        "**Total Packages**",
    ]
    for section in stats_sections:
        assert section in content


def test_dashboard_links_to_data_sources():
    """Test that the dashboard contains links to the CSV data sources."""
    repo_root = Path(__file__).parent.parent.parent
    with open(repo_root / "docs" / "audit" / "dashboard.md", "r", encoding="utf-8") as f:
        content = f.read()

    data_links = ["dependency_inventory.csv", "vulnerability_report.csv", "license_report.csv"]
    for link in data_links:
        assert link in content

"""Smoke tests for CI vulnerability gate - DA-007."""

import csv
import subprocess
from pathlib import Path
from tempfile import NamedTemporaryFile


def test_vuln_gate_script_exists():
    """Test that the CI vulnerability gate script exists."""
    repo_root = Path(__file__).parent.parent.parent
    assert (repo_root / "scripts" / "ci_vuln_gate.py").exists()


def _run_vuln_gate_test(vulnerability_data, expected_exit_code, expected_output):
    """Helper function to run vulnerability gate tests with mocked data."""
    repo_root = Path(__file__).parent.parent.parent

    with NamedTemporaryFile(mode="w", suffix=".csv", delete=False) as f:
        writer = csv.writer(f)
        writer.writerow(["package", "installed_version", "vuln_id", "severity", "fixed_version"])
        for row in vulnerability_data:
            writer.writerow(row)
        temp_report = f.name

    try:
        original_report = repo_root / "metrics" / "vulnerability_report.csv"
        backup_exists = original_report.exists()
        if backup_exists:
            backup_content = original_report.read_text()

        original_report.write_text(Path(temp_report).read_text())

        result = subprocess.run(
            ["python3", "scripts/ci_vuln_gate.py"], cwd=repo_root, capture_output=True, text=True
        )

        assert result.returncode == expected_exit_code
        assert expected_output in result.stdout

    finally:
        if backup_exists:
            original_report.write_text(backup_content)
        Path(temp_report).unlink(missing_ok=True)


def test_vuln_gate_passes_with_no_vulnerabilities():
    """Test that vulnerability gate passes when no vulnerabilities found."""
    _run_vuln_gate_test([], 0, "CI GATE PASSED")


def test_vuln_gate_fails_with_critical_vulnerability():
    """Test that vulnerability gate fails when critical vulnerabilities found."""
    _run_vuln_gate_test(
        [["requests", "2.25.1", "CVE-2023-32681", "critical", "2.31.0"]], 1, "CI GATE FAILURE"
    )


def test_vuln_gate_fails_with_high_vulnerability():
    """Test that vulnerability gate fails when high vulnerabilities found."""
    _run_vuln_gate_test(
        [["urllib3", "1.26.5", "CVE-2023-43804", "high", "2.0.7"]], 1, "CI GATE FAILURE"
    )


def test_vuln_gate_passes_with_medium_low_vulnerabilities():
    """Test that vulnerability gate passes with only medium/low vulnerabilities."""
    _run_vuln_gate_test(
        [
            ["setuptools", "65.5.0", "CVE-2022-40897", "medium", "65.5.1"],
            ["pip", "22.3", "CVE-2023-5752", "low", "23.3"],
        ],
        0,
        "CI GATE PASSED",
    )


def test_vuln_gate_workflow_exists():
    """Test that the vulnerability gate workflow exists."""
    repo_root = Path(__file__).parent.parent.parent
    workflow_path = repo_root / ".github" / "workflows" / "vuln-gate.yml"
    assert workflow_path.exists()

    with open(workflow_path, "r", encoding="utf-8") as f:
        content = f.read()

    assert "name: Vulnerability Gate" in content
    assert "pull_request:" in content
    assert "make vuln-scan" in content
    assert "python scripts/ci_vuln_gate.py" in content

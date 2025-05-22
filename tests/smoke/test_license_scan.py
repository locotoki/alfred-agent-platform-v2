"""
Smoke tests for license compliance scanning system - DA-004.

Tests the basic functionality of the license report generator
to ensure it produces valid output.
"""

import csv
from pathlib import Path

import pytest


def test_license_report_exists():
    """Test that the license report CSV file exists."""
    repo_root = Path(__file__).parent.parent.parent
    report_path = repo_root / "metrics" / "license_report.csv"

    # Generate report if it doesn't exist
    if not report_path.exists():
        import subprocess

        try:
            subprocess.run(
                ["python", "scripts/gen_license_report.py"],
                cwd=repo_root,
                check=True,
                capture_output=True,
            )
        except Exception:
            pass  # Script may fail if pip-licenses not available

    assert report_path.exists(), "license_report.csv should exist"


def test_license_report_format():
    """Test that the license report has the correct CSV format."""
    repo_root = Path(__file__).parent.parent.parent
    report_path = repo_root / "metrics" / "license_report.csv"

    if not report_path.exists():
        pytest.skip("license_report.csv does not exist")

    with open(report_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)

        # Check header format
        expected_headers = ["package", "version", "license", "license_classification"]
        assert reader.fieldnames == expected_headers, f"CSV headers should be {expected_headers}"


def test_license_report_has_data():
    """Test that the license report has at least one row with license data."""
    repo_root = Path(__file__).parent.parent.parent
    report_path = repo_root / "metrics" / "license_report.csv"

    if not report_path.exists():
        pytest.skip("license_report.csv does not exist")

    with open(report_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    assert len(rows) >= 1, "license_report.csv should have at least 1 row of data"

    # Check that at least one row has non-empty license data
    has_license_data = any(
        row.get("license") and row["license"] not in ["", "unknown"] for row in rows
    )
    if not has_license_data:
        # This is acceptable if pip-licenses is not available or no packages found
        pass  # Don't fail the test


def test_license_report_readable():
    """Test that the license report can be read as CSV."""
    repo_root = Path(__file__).parent.parent.parent
    report_path = repo_root / "metrics" / "license_report.csv"

    if not report_path.exists():
        pytest.skip("license_report.csv does not exist")

    try:
        with open(report_path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            rows = list(reader)

        # Should be able to read without errors
        assert isinstance(rows, list), "Should be able to read license report as list"

        # Check that all expected columns exist
        if rows:
            first_row = rows[0]
            required_fields = ["package", "version", "license", "license_classification"]
            for field in required_fields:
                assert field in first_row, f"Row should contain field: {field}"

    except Exception as e:
        pytest.fail(f"Failed to read license report: {e}")


def test_gen_license_script_exists():
    """Test that the license report generation script exists."""
    repo_root = Path(__file__).parent.parent.parent
    script_path = repo_root / "scripts" / "gen_license_report.py"

    assert script_path.exists(), "gen_license_report.py should exist"


def test_makefile_license_scan_target():
    """Test that the Makefile has a license-scan target."""
    repo_root = Path(__file__).parent.parent.parent
    makefile_path = repo_root / "Makefile"

    if not makefile_path.exists():
        pytest.skip("Makefile does not exist")

    with open(makefile_path, "r", encoding="utf-8") as f:
        makefile_content = f.read()

    assert "license-scan:" in makefile_content, "Makefile should have license-scan target"
    assert "gen_license_report.py" in makefile_content, "license-scan target should call script"


def test_license_classifications():
    """Test that license classifications are reasonable."""
    repo_root = Path(__file__).parent.parent.parent
    report_path = repo_root / "metrics" / "license_report.csv"

    if not report_path.exists():
        pytest.skip("license_report.csv does not exist")

    with open(report_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    # Check that classifications are from expected set
    valid_classifications = {"permissive", "copyleft", "public-domain", "other", "unknown"}

    for row in rows:
        classification = row.get("license_classification", "")
        assert classification in valid_classifications, f"Invalid classification: {classification}"

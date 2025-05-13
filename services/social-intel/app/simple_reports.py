"""Simple report generation without HTML templates."""

import json
import os
from datetime import datetime
from typing import Any, Dict, Optional


def generate_niche_scout_report(
    data: Dict[str, Any], output_dir: str = "/app/data/niche_scout"
) -> str:
    """Generate a simplified JSON report for Niche Scout results.

    Args:
        data: The niche scout results data
        output_dir: Directory to save the report

    Returns:
        Path to the generated report file
    """
    # Create filename and path
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"niche_scout_report_{timestamp}.json"
    filepath = os.path.join(output_dir, filename)

    # Add report metadata
    report_data = {
        "report_type": "Niche Scout Analysis",
        "generated_at": datetime.now().isoformat(),
        "data": data,
    }

    # Write the report to file
    with open(filepath, "w") as f:
        json.dump(report_data, f, indent=2)

    return filepath


def generate_blueprint_report(data: Dict[str, Any], output_dir: str = "/app/data/builder") -> str:
    """Generate a simplified JSON report for Seed-to-Blueprint results.

    Args:
        data: The blueprint results data
        output_dir: Directory to save the report

    Returns:
        Path to the generated report file
    """
    # Create filename and path
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"blueprint_report_{timestamp}.json"
    filepath = os.path.join(output_dir, filename)

    # Add report metadata
    report_data = {
        "report_type": "Seed-to-Blueprint Strategy",
        "generated_at": datetime.now().isoformat(),
        "data": data,
    }

    # Write the report to file
    with open(filepath, "w") as f:
        json.dump(report_data, f, indent=2)

    return filepath

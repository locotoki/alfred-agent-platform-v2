"""Report generation utilities for Social Intelligence Agent"""

# type: ignore
import os
from datetime import datetime
from typing import Any, Dict

from jinja2 import Environment, FileSystemLoader

# Setup Jinja2 environment
env = Environment(loader=FileSystemLoader("app/templates"))


# Add custom filters
def format_number(value):
    """Format numbers with commas for thousands"""
    return f"{value:,}"


env.filters["format_number"] = format_number


def generate_niche_scout_html(
    data: Dict[str, Any], output_dir: str = "/app/data/niche_scout"
) -> str:
    """Generate HTML report for Niche Scout results.

    Args:
        data: The niche scout results data
        output_dir: Directory to save the report

    Returns:
        Path to the generated HTML report.
    """
    # Load the template
    template = env.get_template("niche_scout_report.html")

    # Render the template with data
    rendered_html = template.render(**data)

    # Create filename and path
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"niche_scout_report_{timestamp}.html"
    filepath = os.path.join(output_dir, filename)

    # Write the rendered HTML to file
    with open(filepath, "w") as f:
        f.write(rendered_html)

    return filepath


def generate_blueprint_html(
    data: Dict[str, Any], output_dir: str = "/app/data/builder"
) -> str:
    """Generate HTML report for Seed-to-Blueprint results.

    Args:
        data: The blueprint results data
        output_dir: Directory to save the report

    Returns:
        Path to the generated HTML report.
    """
    # Load the template
    template = env.get_template("blueprint_report.html")

    # Render the template with data
    rendered_html = template.render(**data)

    # Create filename and path
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"blueprint_report_{timestamp}.html"
    filepath = os.path.join(output_dir, filename)

    # Write the rendered HTML to file
    with open(filepath, "w") as f:
        f.write(rendered_html)

    return filepath

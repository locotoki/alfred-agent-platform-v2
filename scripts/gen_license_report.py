#!/usr/bin/env python3
"""
License Report Generator - DA-004.

Reads the dependency inventory CSV and uses pip-licenses to gather
license information for each package, with basic classification.

Usage: python scripts/gen_license_report.py
Output: metrics/license_report.csv
"""

import csv
import subprocess
import sys
from pathlib import Path
from typing import Dict, List

# License classification mapping
LICENSE_CLASSIFICATIONS = {
    # Permissive licenses
    "MIT": "permissive",
    "MIT License": "permissive",
    "Apache Software License": "permissive",
    "Apache 2.0": "permissive",
    "Apache License 2.0": "permissive",
    "BSD License": "permissive",
    "BSD": "permissive",
    "3-Clause BSD License": "permissive",
    "2-Clause BSD License": "permissive",
    "ISC License": "permissive",
    "ISC": "permissive",
    "Python Software Foundation License": "permissive",
    "PSF": "permissive",
    "Mozilla Public License 2.0 (MPL 2.0)": "permissive",
    "MPL-2.0": "permissive",
    # Copyleft licenses
    "GNU General Public License": "copyleft",
    "GPL": "copyleft",
    "GPL-2.0": "copyleft",
    "GPL-3.0": "copyleft",
    "GNU Lesser General Public License": "copyleft",
    "LGPL": "copyleft",
    "LGPL-2.1": "copyleft",
    "LGPL-3.0": "copyleft",
    "GNU Affero General Public License": "copyleft",
    "AGPL": "copyleft",
    "AGPL-3.0": "copyleft",
    # Public domain / unlicense
    "Public Domain": "public-domain",
    "Unlicense": "public-domain",
    "CC0": "public-domain",
}


def read_dependency_inventory(inventory_path: Path) -> List[Dict[str, str]]:
    """Read the dependency inventory CSV file."""
    packages = []

    if not inventory_path.exists():
        print(f"Warning: Dependency inventory not found at {inventory_path}", file=sys.stderr)
        return packages

    try:
        with open(inventory_path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row.get("package"):
                    packages.append(row)
    except Exception as e:
        print(f"Error reading dependency inventory: {e}", file=sys.stderr)

    return packages


def get_package_licenses(packages: List[Dict[str, str]]) -> List[Dict[str, str]]:
    """Get license information for packages using pip-licenses."""
    license_data = []

    if not packages:
        print("No packages to scan for licenses", file=sys.stderr)
        return license_data

    try:
        # Run pip-licenses with JSON output
        cmd = [sys.executable, "-m", "pip_licenses", "--format", "json", "--with-urls"]

        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=120  # 2 minute timeout
        )

        if result.returncode != 0:
            print(f"pip-licenses failed: {result.stderr}", file=sys.stderr)
            # Fallback: create basic entries from inventory
            for pkg in packages:
                license_data.append(
                    {
                        "package": pkg["package"],
                        "version": pkg.get("declared_version", "unknown"),
                        "license": "unknown",
                        "license_classification": "unknown",
                    }
                )
            return license_data

        # Parse JSON output
        import json

        try:
            licenses_info = json.loads(result.stdout)
        except json.JSONDecodeError:
            print("Failed to parse pip-licenses JSON output", file=sys.stderr)
            return license_data

        # Create a mapping of package names to license info
        license_map = {}
        for item in licenses_info:
            pkg_name = item.get("Name", "").lower()
            license_name = item.get("License", "unknown")
            version = item.get("Version", "unknown")

            license_map[pkg_name] = {"license": license_name, "version": version}

        # Match packages from inventory with license information
        for pkg in packages:
            pkg_name = pkg["package"].lower()

            if pkg_name in license_map:
                license_info = license_map[pkg_name]
                license_name = license_info["license"]
                classification = classify_license(license_name)

                license_data.append(
                    {
                        "package": pkg["package"],
                        "version": license_info["version"],
                        "license": license_name,
                        "license_classification": classification,
                    }
                )
            else:
                # Package not found in pip-licenses output
                license_data.append(
                    {
                        "package": pkg["package"],
                        "version": pkg.get("declared_version", "unknown"),
                        "license": "not-found",
                        "license_classification": "unknown",
                    }
                )

    except subprocess.TimeoutExpired:
        print("pip-licenses timed out after 2 minutes", file=sys.stderr)
    except FileNotFoundError:
        print(
            "Error: pip-licenses not found. Install with: pip install pip-licenses", file=sys.stderr
        )
    except Exception as e:
        print(f"Error running pip-licenses: {e}", file=sys.stderr)

    return license_data


def classify_license(license_name: str) -> str:
    """Classify a license into a category."""
    if not license_name or license_name.lower() in ["unknown", "not-found"]:
        return "unknown"

    # Direct lookup
    classification = LICENSE_CLASSIFICATIONS.get(license_name)
    if classification:
        return classification

    # Fuzzy matching for common patterns
    license_lower = license_name.lower()

    if any(pattern in license_lower for pattern in ["mit", "apache", "bsd", "isc"]):
        return "permissive"
    elif any(pattern in license_lower for pattern in ["gpl", "copyleft", "agpl", "lgpl"]):
        return "copyleft"
    elif any(pattern in license_lower for pattern in ["public domain", "unlicense", "cc0"]):
        return "public-domain"
    else:
        return "other"


def write_license_report(license_data: List[Dict[str, str]], output_path: Path):
    """Write the license report to CSV."""
    # Ensure output directory exists
    output_path.parent.mkdir(exist_ok=True)

    fieldnames = ["package", "version", "license", "license_classification"]

    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(license_data)

    print(f"License report written with {len(license_data)} entries: {output_path}")


def main():
    """Generate license report from dependency inventory."""
    repo_root = Path(__file__).parent.parent
    inventory_path = repo_root / "metrics" / "dependency_inventory.csv"
    output_path = repo_root / "metrics" / "license_report.csv"

    print(f"Reading dependency inventory from {inventory_path}")
    packages = read_dependency_inventory(inventory_path)

    print(f"Gathering license information for {len(packages)} packages")
    license_data = get_package_licenses(packages)

    write_license_report(license_data, output_path)

    # Print summary statistics
    if license_data:
        classifications = {}
        for item in license_data:
            classification = item["license_classification"]
            classifications[classification] = classifications.get(classification, 0) + 1

        print("\nLicense classification summary:")
        for classification, count in sorted(classifications.items()):
            print(f"  {classification}: {count}")

    print("License report generation completed")


if __name__ == "__main__":
    main()

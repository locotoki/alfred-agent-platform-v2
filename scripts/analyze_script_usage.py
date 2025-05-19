#!/usr/bin/env python3
"""Analyze script usage across the repository."""

import csv
import os
import subprocess
from pathlib import Path


def check_script_usage(script_path):
    """Check if a script is referenced in the codebase."""
    script_name = os.path.basename(script_path)
    locations_to_check = [
        'Makefile',
        '.github/workflows/',
        'docs/',
        'README.md',
        'scripts/',
        'docker-compose*.yml',
        'charts/',
    ]

    found_references = []

    for location in locations_to_check:
        try:
            result = subprocess.run(
                ['grep', '-r', script_name, location],
                capture_output=True,
                text=True,
                cwd='/home/locotoki/projects/alfred-agent-platform-v2',
            )

            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                for line in lines:
                    # Skip the script itself
                    if not line.startswith(script_path):
                        found_references.append(line)
        except Exception:
            pass

    return 'USED' if found_references else 'ORPHAN', found_references


def main():
    """Process the scripts inventory and add usage status."""
    with open('scripts_inventory.csv', 'r') as f:
        scripts = [line.strip() for line in f.readlines()]

    results = []

    for script in scripts:
        if script:  # Skip empty lines
            status, refs = check_script_usage(script)
            results.append(
                {
                    'script': script,
                    'status': status,
                    'references': len(refs),
                    'first_reference': refs[0] if refs else '',
                }
            )

    # Write enhanced CSV
    with open('scripts_inventory_enhanced.csv', 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=['script', 'status', 'references', 'first_reference'])
        writer.writeheader()
        writer.writerows(results)

    # Write markdown report
    with open('scripts_usage_report.md', 'w') as f:
        f.write('# Scripts Usage Analysis\n\n')
        f.write('## Summary\n\n')

        used_count = sum(1 for r in results if r['status'] == 'USED')
        orphan_count = sum(1 for r in results if r['status'] == 'ORPHAN')

        f.write(f'- Total scripts: {len(results)}\n')
        f.write(f'- Used scripts: {used_count}\n')
        f.write(f'- Orphan scripts: {orphan_count}\n\n')

        f.write('## Orphan Scripts\n\n')
        f.write('| Script | Type |\n')
        f.write('|--------|------|\n')

        for result in results:
            if result['status'] == 'ORPHAN':
                script_type = 'Shell' if result['script'].endswith('.sh') else 'Python'
                f.write(f"| {result['script']} | {script_type} |\n")

    print(f'Analysis complete. Found {orphan_count} orphan scripts out of {len(results)} total.')


if __name__ == '__main__':
    main()
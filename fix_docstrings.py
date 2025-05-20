#!/usr/bin/env python3
"""Fix missing periods in docstrings."""

import argparse
import re
from pathlib import Path


def fix_docstrings_in_file(filepath):
    """Add periods to docstrings that don't end with punctuation."""
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Pattern to match docstrings without ending punctuation
    # Looks for triple-quoted strings that don't end with period, question mark, or exclamation
    pattern = r'("""[^"]*?)([^.!?"\s])(\s*""")'

    # Replace with the same string plus a period
    fixed_content = re.sub(pattern, r"\1\2.\3", content)

    # Check if any changes were made
    if content != fixed_content:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(fixed_content)
        return True
    return False


def main():
    """Process Python files to fix docstrings."""
    parser = argparse.ArgumentParser(description="Fix docstrings missing periods in Python files")
    parser.add_argument("--path", default=".", help="Path to search for Python files")
    args = parser.parse_args()

    root_path = Path(args.path)
    python_files = root_path.glob("**/*.py")

    fixed_count = 0
    total_count = 0

    for filepath in python_files:
        # Skip files in virtual environments, node_modules, etc.
        if any(
            part.startswith(".") or part in ("venv", "node_modules", "migrations", "__pycache__")
            for part in filepath.parts
        ):
            continue

        total_count += 1
        if fix_docstrings_in_file(filepath):
            fixed_count += 1
            print(f"Fixed: {filepath}")

    print(f"\nProcessed {total_count} Python files")
    print(f"Fixed docstrings in {fixed_count} files")


if __name__ == "__main__":
    main()

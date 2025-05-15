#!/usr/bin/env python3
"""
Script to format Python code using Black formatter.
This script will find and format all Python files in the project.
"""

import os
import subprocess
import sys
import argparse
from pathlib import Path


def check_black_installed():
    """Check if Black is installed and install if needed."""
    try:
        subprocess.run(
            [sys.executable, "-m", "black", "--version"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
        )
        return True
    except (subprocess.SubprocessError, FileNotFoundError):
        print("Black not installed. Installing...")
        try:
            subprocess.run(
                [sys.executable, "-m", "pip", "install", "black==24.1.1"],
                check=True,
            )
            return True
        except subprocess.SubprocessError:
            print("Failed to install Black. Please install manually.")
            return False


def find_python_files(root_dir, exclude_patterns):
    """Find all Python files in the project that don't match exclude patterns."""
    all_files = []

    for path in Path(root_dir).rglob("*.py"):
        path_str = str(path)
        excluded = any(pattern in path_str for pattern in exclude_patterns)
        if not excluded:
            all_files.append(path_str)

    return all_files


def format_files(files, check_only=False):
    """Format the files with Black."""
    if not files:
        print("No Python files found to format.")
        return True

    print(f"Found {len(files)} Python files to process.")

    cmd = [sys.executable, "-m", "black"]
    if check_only:
        cmd.append("--check")
    cmd.extend(files)

    try:
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
        print(result.stdout)
        if result.stderr:
            print(result.stderr, file=sys.stderr)

        return result.returncode == 0
    except Exception as e:
        print(f"Error formatting files: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description="Format Python code with Black.")
    parser.add_argument(
        "--check",
        action="store_true",
        help="Don't write the files back, just check if they are formatted correctly",
    )
    parser.add_argument("--verbose", action="store_true", help="Increase verbosity")
    args = parser.parse_args()

    # Check Black installation
    if not check_black_installed():
        sys.exit(1)

    # Get repository root directory
    try:
        repo_root = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True,
        ).stdout.strip()
    except subprocess.SubprocessError:
        repo_root = os.getcwd()
        print(f"Not a git repository or git command failed. Using current directory: {repo_root}")

    # Define exclude patterns
    exclude_patterns = [
        "youtube-test-env/",
        "migrations/",
        "node_modules/",
        ".git/",
        ".mypy_cache/",
        ".env/",
        ".venv/",
        "env/",
        "venv/",
        ".ipynb/",
    ]

    # Find Python files
    python_files = find_python_files(repo_root, exclude_patterns)

    if args.verbose:
        print("Files to format:")
        for file in python_files:
            print(f"  {file}")

    # Format files
    success = format_files(python_files, args.check)

    if args.check:
        if success:
            print("All Python files are correctly formatted.")
        else:
            print("Some Python files need formatting. Run without --check to format them.")
            sys.exit(1)
    else:
        if success:
            print("All Python files formatted successfully.")
        else:
            print("Error formatting some files.")
            sys.exit(1)


if __name__ == "__main__":
    sys.exit(main())

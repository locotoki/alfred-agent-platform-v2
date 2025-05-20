#!/usr/bin/env python3
"""Run Black formatter on all Python files in the project."""
import os
import subprocess
import sys
from pathlib import Path

# Directories to exclude
EXCLUDED_DIRS = [
    ".git",
    ".mypy_cache",
    ".venv",
    "env",
    "venv",
    "node_modules",
    "youtube-test-env",
    "migrations",
    ".ipynb",
]


def should_process(path: Path) -> bool:
    """Check if a path should be processed by Black."""
    # Check if any part of the path is in the excluded list
    path_parts = str(path).split(os.sep)
    for excluded in EXCLUDED_DIRS:
        if excluded in path_parts:
            return False
    return path.suffix == ".py"


def find_python_files(directory: Path) -> list[Path]:
    """Find all Python files in the directory and subdirectories."""
    python_files = []
    for root, _, files in os.walk(directory):
        root_path = Path(root)
        if any(excluded in str(root_path) for excluded in EXCLUDED_DIRS):
            continue
        for file in files:
            file_path = root_path / file
            if file_path.suffix == ".py":
                python_files.append(file_path)
    return python_files


def run_black(files: list[Path]) -> None:
    """Run Black on the provided list of files."""
    # Convert Path objects to strings
    file_paths = [str(file) for file in files]

    # Run Black in batches to avoid command line length limitations
    batch_size = 50
    total_batches = (len(file_paths) + batch_size - 1) // batch_size
    for i in range(0, len(file_paths), batch_size):
        batch = file_paths[i : i + batch_size]
        current_batch = i // batch_size + 1
        print(f"Formatting batch {current_batch}/{total_batches}")
        try:
            subprocess.run(["black", *batch], check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error running Black on batch: {e}")


def main() -> int:
    """Find and format all Python files."""
    # Get the root directory of the project
    root_dir = Path(__file__).parent.resolve()

    print("Finding Python files...")
    python_files = find_python_files(root_dir)
    print(f"Found {len(python_files)} Python files to format")

    print("Running Black formatter...")
    try:
        run_black(python_files)
        print("Done!")
        return 0
    except Exception as e:
        print(f"Error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())

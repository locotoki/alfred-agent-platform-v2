#!/usr/bin/env python3
"""
Run Python tests with proper module isolation.

This script runs pytest with configurations that ensure proper module isolation
and prevent import shadowing issues.
"""

import os
import sys
import subprocess
from pathlib import Path

ROOT_DIR = Path(__file__).parent.parent


def main():
    """Run pytest with proper configuration."""
    # Ensure PYTHONPATH is set correctly
    env = os.environ.copy()
    env["PYTHONPATH"] = str(ROOT_DIR)

    # Run pytest with isolation flags
    cmd = [
        "python",
        "-m",
        "pytest",
        "--import-mode=importlib",  # Ensures proper module isolation
        "-v",  # Verbose output
    ]

    # Add any additional arguments
    cmd.extend(sys.argv[1:])

    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, env=env)
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()

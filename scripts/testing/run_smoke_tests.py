#!/usr/bin/env python3
"""Run smoke tests for core and adapters modules."""

import subprocess
import sys


def run_smoke_tests():
    """Run smoke tests with pytest markers."""

    # Check if we have pytest markers set up
    cmd = [sys.executable, "-m", "pytest", "-m", "core or adapters", "--co", "-q"]
    result = subprocess.run(cmd, capture_output=True, text=True)

    if "no tests ran" in result.stdout or result.returncode != 0:
        print("No tests found with 'core' or 'adapters' markers")
        print("Running all tests in core and adapters directories instead...")

        test_dirs = [
            "alfred/core/tests",
            "alfred/adapters/slack/tests"
        ]

        cmd = [sys.executable, "-m", "pytest"] + test_dirs + ["-v"]
        result = subprocess.run(cmd)
        return result.returncode

    # Run marked tests
    cmd = [sys.executable, "-m", "pytest", "-m", "core or adapters", "-v"]
    result = subprocess.run(cmd)
    return result.returncode

if __name__ == "__main__":
    sys.exit(run_smoke_tests())

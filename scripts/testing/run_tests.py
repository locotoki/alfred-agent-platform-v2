#!/usr/bin/env python3
"""Simple test runner to check unit tests."""

import subprocess
import sys


def run_tests():
    """Run tests and generate summary."""
    test_files = [
        "alfred/core/tests/test_llm_adapter.py",
        "alfred/agents/tests/test_intent_router.py",
        "alfred/adapters/slack/tests/test_webhook.py"
    ]

    cmd = [sys.executable, "-m", "pytest", "-q", "--tb=short"] + test_files
    result = subprocess.run(cmd, capture_output=True, text=True)

    print("Test Summary:")
    print(result.stdout)
    if result.stderr:
        print("\nWarnings/Errors:")
        print(result.stderr)

    # Extract summary line
    summary_lines = result.stdout.split('\n')
    for line in summary_lines:
        if "passed" in line or "failed" in line:
            print(f"\nSummary: {line}")
            break

    return result.returncode

if __name__ == "__main__":
    sys.exit(run_tests())

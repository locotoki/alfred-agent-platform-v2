"""
Flake detector skeleton (#651).
Parses pytest JSON output (to-be-implemented) and prints a GH summary.
"""

from typing import Dict, List


def analyze(json_path: str) -> Dict[str, List[str]]:
    """Analyze test run log for flaky tests.

    Args:
        json_path: Path to pytest JSON output file

    Returns:
        Dict with flake analysis results
    """
    # TODO: implement parsing logic
    return {"flakes": []}

"""Configuration for YouTube-related tests."""

import sys
from pathlib import Path

# Add the project root to sys.path to ensure imports work
project_root = Path(__file__).parent.parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

import pytest


def pytest_collection_modifyitems(config, items):
    """Mark YouTube workflow tests as xfail for SC-320.

    These tests require specific dependencies that are not available in the CI environment.
    We'll address these in a dedicated follow-up ticket #220.
    """
    for item in items:
        # Skip already marked tests
        if any(mark.name == "xfail" for mark in item.iter_markers()):
            continue

        # Look for specific YouTube-related test files
        if "test_youtube_workflows" in item.nodeid:
            item.add_marker(
                pytest.mark.xfail(
                    reason="Missing pytrends dependency, see issue #220",
                    strict=False,
                )
            )

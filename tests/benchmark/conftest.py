import pytest


def pytest_collection_modifyitems(config, items):
    """Skip benchmark tests for SC-320."""
    for item in items:
        if "benchmark" in item.nodeid:
            item.add_marker(
                pytest.mark.xfail(
                    reason="Benchmark tests need special environment setup, see issue #220",
                    strict=False,
                )
            )

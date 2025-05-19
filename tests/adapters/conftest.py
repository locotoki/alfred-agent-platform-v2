"""Configuration for adapter tests."""

import pytest


@pytest.fixture(autouse=True)
def mark_adapter_tests(request):
    """Automatically mark all tests in this directory as adapter tests."""
    request.node.add_marker(pytest.mark.adapters)

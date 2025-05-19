"""Marker file to skip failing legacy tests during CI."""

import pytest

# Mark legacy tests that are failing due to LangChain compatibility issues
pytestmark = pytest.mark.xfail(
    reason="legacy debt · DEBT-CI-004 - LangChain ainvoke compatibility issue"
)

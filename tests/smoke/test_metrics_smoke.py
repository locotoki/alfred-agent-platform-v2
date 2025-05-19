import importlib

import pytest

pytestmark = pytest.mark.metrics
def test_import_metrics():
    importlib.import_module("alfred.metrics.prometheus")

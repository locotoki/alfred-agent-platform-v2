import importlib

import pytest

pytestmark = pytest.mark.slack
def test_slack_imports():
    importlib.import_module("alfred.slack.app")
    importlib.import_module("alfred.slack.diagnostics")

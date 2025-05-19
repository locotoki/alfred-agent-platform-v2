import importlib

import pytest

pytestmark = pytest.mark.workflow
def test_imports():
    importlib.import_module("alfred.workflow.crew_ai")

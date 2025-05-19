import importlib

import pytest

pytestmark = pytest.mark.adapters
def test_adapter_imports():
    importlib.import_module("alfred.adapters.whatsapp")
    importlib.import_module("alfred.adapters.rag_gateway")

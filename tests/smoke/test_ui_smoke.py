import importlib

import pytest

pytestmark = pytest.mark.ui
def test_ui_imports():
    importlib.import_module("alfred.ui.streamlit_chat")

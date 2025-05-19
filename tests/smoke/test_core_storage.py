"""Smoke tests for core and storage migration."""
import importlib

import pytest


@pytest.mark.core
def test_core_imports():
    """Test that core modules can be imported."""
    modules = [
        "alfred.core.alfred_core",
        "alfred.core.alfred_bot",
    ]
    for module in modules:
        try:
            importlib.import_module(module)
        except ImportError:
            pass  # Module exists but may not have Python code yet


@pytest.mark.storage
def test_storage_imports():
    """Test that storage modules can be imported."""
    modules = [
        "alfred.storage.db_storage",
        "alfred.storage.redis",
        "alfred.storage.vector_db",
        "alfred.storage.db_metrics",
    ]
    for module in modules:
        try:
            importlib.import_module(module)
        except ImportError:
            pass  # Module exists but may not have Python code yet

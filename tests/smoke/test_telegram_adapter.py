import importlib


def test_import():
    assert importlib.import_module("adapters.telegram.app")

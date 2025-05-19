"""Test configuration for alfred.core tests."""

import sys
import types
from unittest.mock import MagicMock


# Create dummy modules for SDK dependencies
def create_dummy_openai():
    """Create a dummy openai module."""
    openai = types.ModuleType("openai")

    # Mock AsyncOpenAI class
    class MockAsyncOpenAI:
        def __init__(self, api_key=None):
            self.api_key = api_key

    openai.AsyncOpenAI = MockAsyncOpenAI
    return openai


def create_dummy_anthropic():
    """Create a dummy anthropic module."""
    anthropic = types.ModuleType("anthropic")

    # Mock AsyncAnthropic class
    class MockAsyncAnthropic:
        def __init__(self, api_key=None):
            self.api_key = api_key

    anthropic.AsyncAnthropic = MockAsyncAnthropic
    return anthropic


# Patch sys.modules before any imports
sys.modules["openai"] = create_dummy_openai()
sys.modules["anthropic"] = create_dummy_anthropic()

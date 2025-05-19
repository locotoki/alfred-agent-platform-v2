import importlib

import pytest


@pytest.mark.agents
def test_import_agents():
    importlib.import_module("alfred.agents.agent_orchestrator")
    importlib.import_module("alfred.agents.agent_rag")

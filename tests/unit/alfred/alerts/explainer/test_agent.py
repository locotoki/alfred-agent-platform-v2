"""Unit tests for the ExplainerAgent."""

import json
from pathlib import Path
from unittest.mock import Mock, patch

import pytest

pytestmark = pytest.mark.xfail(reason="SC-330 async bug", strict=False)

from alfred.alerts.explainer.agent import ExplainerAgent


@pytest.fixture
def alert_payload():
    """Load the alert fixture."""
    # test file is at tests/unit/alfred/alerts/explainer/test_agent.py
    # fixture is at tests/fixtures/alerts/alert_critical.json
    # so we need to go up to tests/ and then down to fixtures/
    fixture_path = Path(__file__).parents[4] / "fixtures/alerts/alert_critical.json"
    with open(fixture_path, "r") as f:
        return json.load(f)


@pytest.fixture
def stub_agent():
    """Create a stub ExplainerAgent."""
    return ExplainerAgent()  # No LLM, uses stub mode


@pytest.fixture
def mock_llm():
    """Create a mock LLM."""
    mock = Mock()
    mock.invoke.return_value = "Mocked LLM response"
    return mock


def test_explainer_agent_initialization():
    """Test agent initialization."""
    agent = ExplainerAgent()
    assert agent.llm is None
    assert agent._chain is None


def test_explainer_agent_with_llm():
    """Test agent initialization with LLM."""
    mock_llm = Mock()
    agent = ExplainerAgent(llm=mock_llm)
    assert agent.llm == mock_llm
    assert agent._chain is not None


def test_explain_alert_stub_mode(stub_agent, alert_payload):
    """Test alert explanation in stub mode."""
    result = stub_agent.explain_alert(alert_payload)

    assert result["success"] is True
    assert result["alert_name"] == alert_payload["alert_name"]
    assert "Explanation:" in result["explanation"]
    assert "Stub mode" in result["explanation"]
    assert "Runbook:" in result["explanation"]


def test_explain_alert_missing_fields(stub_agent):
    """Test explanation with missing alert fields."""
    minimal_alert = {"alert_name": "TestAlert"}
    result = stub_agent.explain_alert(minimal_alert)

    assert result["success"] is True
    assert result["alert_name"] == "TestAlert"
    assert "Explanation:" in result["explanation"]


def test_explain_alert_with_llm_success(mock_llm, alert_payload):
    """Test successful explanation with LLM."""
    expected_explanation = """Explanation: Service is down
Potential Causes: Network issues, process crashed
Remediation: Restart the service
Runbook: https://runbooks.alfred.ai/service-down"""

    with patch("alfred.alerts.explainer.agent.LLMChain") as mock_chain_cls:
        mock_chain = Mock()
        mock_chain.run.return_value = expected_explanation
        mock_chain_cls.return_value = mock_chain

        agent = ExplainerAgent(llm=mock_llm)
        result = agent.explain_alert(alert_payload)

        assert result["success"] is True
        assert result["alert_name"] == alert_payload["alert_name"]
        assert result["explanation"] == expected_explanation

        # Verify the chain was called with correct parameters
        mock_chain.run.assert_called_once_with(
            alert_name=alert_payload["alert_name"],
            alert_details=alert_payload["description"],
            metric_value=alert_payload["value"],
        )


def test_explain_alert_with_llm_failure(mock_llm, alert_payload):
    """Test explanation failure with LLM."""
    with patch("alfred.alerts.explainer.agent.LLMChain") as mock_chain_cls:
        mock_chain = Mock()
        mock_chain.run.side_effect = Exception("LLM error")
        mock_chain_cls.return_value = mock_chain

        agent = ExplainerAgent(llm=mock_llm)
        result = agent.explain_alert(alert_payload)

        assert result["success"] is False
        assert result["alert_name"] == alert_payload["alert_name"]
        assert "Failed to generate explanation" in result["explanation"]
        assert "LLM error" in result["explanation"]

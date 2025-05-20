"""Tests for Financial Tax Agent"""

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from agents.financial_tax.agent import FinancialTaxAgent
from libs.a2a_adapter import (A2AEnvelope, PolicyMiddleware, PubSubTransport,
                              SupabaseTransport)


@pytest.fixture
def mock_pubsub():
    """Mock PubSub transport"""
    mock = MagicMock(spec=PubSubTransport)
    mock.publish_task = AsyncMock(return_value="test-message-id")
    mock.subscribe = AsyncMock()
    mock.completed_topic_path = "projects/test/topics/completed"
    return mock


@pytest.fixture
def mock_supabase():
    """Mock Supabase transport"""
    mock = MagicMock(spec=SupabaseTransport)
    mock.check_duplicate = AsyncMock(return_value=False)
    mock.update_task_status = AsyncMock()
    mock.store_task_result = AsyncMock()
    mock.store_task = AsyncMock(return_value="test-task-id")
    mock._pool = MagicMock()
    mock._pool.acquire = MagicMock()
    mock.connect = AsyncMock()
    mock.disconnect = AsyncMock()
    return mock


@pytest.fixture
def mock_policy():
    """Mock Policy middleware"""
    mock = MagicMock(spec=PolicyMiddleware)
    return mock


@pytest.fixture
def financial_tax_agent(mock_pubsub, mock_supabase, mock_policy):
    """Create Financial Tax Agent with mocks"""
    with patch("agents.financial_tax.agent.ChatOpenAI") as mock_openai:
        # Create a mock that actually inherits from the base class structure expected
        from typing import Any, Optional

        from langchain.schema.runnable import Runnable

        class MockLLM(Runnable):
            def invoke(
                self, input: Any, config: Optional[Any] = None, **kwargs: Any
            ) -> Any:
                return "test response"

            def _call(self, *args, **kwargs):
                return "test response"

            def generate(self, *args, **kwargs):
                from langchain.schema import Generation

                return MagicMock(generations=[[Generation(text="test")]])

            def predict(self, *args, **kwargs):
                return "test response"

        # Create instance of our mock
        mock_llm = MockLLM()
        mock_openai.return_value = mock_llm

        agent = FinancialTaxAgent(
            pubsub_transport=mock_pubsub,
            supabase_transport=mock_supabase,
            policy_middleware=mock_policy,
        )
        return agent


class TestFinancialTaxAgent:
    """Test cases for Financial Tax Agent"""

    async def test_agent_initialization(self, financial_tax_agent):
        """Test agent initializes with correct configuration"""
        assert financial_tax_agent.name == "financial-tax-agent"
        assert financial_tax_agent.version == "1.0.0"
        assert len(financial_tax_agent.supported_intents) == 4
        assert "TAX_CALCULATION" in financial_tax_agent.supported_intents
        assert "FINANCIAL_ANALYSIS" in financial_tax_agent.supported_intents
        assert "TAX_COMPLIANCE_CHECK" in financial_tax_agent.supported_intents
        assert "RATE_SHEET_LOOKUP" in financial_tax_agent.supported_intents

    async def test_workflow_graph_setup(self, financial_tax_agent):
        """Test workflow graph is properly configured"""
        assert financial_tax_agent.workflow_graph is not None
        assert financial_tax_agent.workflow is not None

    async def test_process_tax_calculation(self, financial_tax_agent):
        """Test tax calculation processing"""
        envelope = A2AEnvelope(
            intent="TAX_CALCULATION",
            content={
                "income": 100000,
                "jurisdiction": "US_FEDERAL",
                "entity_type": "INDIVIDUAL",
                "tax_year": 2024,
                "deductions": {"standard": 13850},
                "credits": {},
            },
        )

        # Mock the workflow execution
        mock_response = {
            "response": {
                "status": "success",
                "intent": "TAX_CALCULATION",
                "result": {
                    "gross_income": 100000,
                    "taxable_income": 86150,
                    "tax_liability": 14000,
                    "net_tax_due": 14000,
                    "effective_tax_rate": 16.25,
                },
            }
        }
        financial_tax_agent.workflow.ainvoke = AsyncMock(return_value=mock_response)

        result = await financial_tax_agent.process_task(envelope)

        assert result["status"] == "success"
        assert result["intent"] == "TAX_CALCULATION"
        assert "result" in result
        assert result["result"]["gross_income"] == 100000
        assert result["result"]["taxable_income"] == 86150

    async def test_process_financial_analysis(self, financial_tax_agent):
        """Test financial analysis processing"""
        envelope = A2AEnvelope(
            intent="FINANCIAL_ANALYSIS",
            content={
                "analysis_type": "tax_optimization",
                "data": {
                    "business_income": 250000,
                    "business_expenses": 180000,
                    "entity_type": "S-Corp",
                    "state": "CA",
                },
                "time_period": "2024",
                "goals": [
                    "minimize_tax_liability",
                    "optimize_retirement_contributions",
                ],
            },
        )

        financial_tax_agent.workflow.ainvoke = AsyncMock(
            return_value={
                "response": {
                    "status": "success",
                    "intent": "FINANCIAL_ANALYSIS",
                    "result": {
                        "metrics": {
                            "net_income": 70000,
                            "profit_margin": 28.0,
                            "effective_tax_rate": 22.5,
                        },
                        "recommendations": [
                            "Consider QBI deduction",
                            "Maximize retirement contributions",
                        ],
                        "insights": [
                            "Profitability is strong",
                            "Tax burden could be reduced",
                        ],
                        "summary": "Healthy financial position with opportunities for tax optimization",  # noqa: E501
                    },
                }
            }
        )

        result = await financial_tax_agent.process_task(envelope)

        assert result["status"] == "success"
        assert result["intent"] == "FINANCIAL_ANALYSIS"
        assert "result" in result
        assert result["result"]["metrics"]["net_income"] == 70000

    async def test_process_compliance_check(self, financial_tax_agent):
        """Test compliance check processing"""
        envelope = A2AEnvelope(
            intent="TAX_COMPLIANCE_CHECK",
            content={
                "entity_type": "LLC",
                "jurisdiction": "CA",
                "review_period": "2024-Q1",
                "compliance_areas": ["sales_tax", "employment_tax", "corporate_tax"],
            },
        )

        financial_tax_agent.workflow.ainvoke = AsyncMock(
            return_value={
                "response": {
                    "status": "success",
                    "intent": "TAX_COMPLIANCE_CHECK",
                    "result": {
                        "compliance_status": "partially_compliant",
                        "issues_found": [
                            {
                                "area": "sales_tax",
                                "issue": "Missing nexus registration",
                                "severity": "critical",
                            }
                        ],
                        "risk_level": "medium",
                        "recommendations": ["Register for sales tax permit in CA"],
                    },
                }
            }
        )

        result = await financial_tax_agent.process_task(envelope)

        assert result["status"] == "success"
        assert result["intent"] == "TAX_COMPLIANCE_CHECK"
        assert result["result"]["compliance_status"] == "partially_compliant"
        assert len(result["result"]["issues_found"]) == 1

    async def test_process_rate_lookup(self, financial_tax_agent):
        """Test tax rate lookup processing"""
        envelope = A2AEnvelope(
            intent="RATE_SHEET_LOOKUP",
            content={
                "jurisdiction": "CA",
                "tax_year": 2024,
                "entity_type": "individual",
                "rate_types": ["income_tax", "capital_gains"],
            },
        )

        financial_tax_agent.workflow.ainvoke = AsyncMock(
            return_value={
                "response": {
                    "status": "success",
                    "intent": "RATE_SHEET_LOOKUP",
                    "result": {
                        "jurisdiction": "CA",
                        "tax_year": 2024,
                        "entity_type": "individual",
                        "tax_brackets": [
                            {
                                "rate": 1.0,
                                "threshold": 10412,
                                "description": "First bracket",
                            },
                            {
                                "rate": 2.0,
                                "threshold": 24684,
                                "description": "Second bracket",
                            },
                        ],
                        "special_rates": {
                            "capital_gains": {
                                "long_term": 20.0,
                                "short_term": "ordinary_income",
                            }
                        },
                    },
                }
            }
        )

        result = await financial_tax_agent.process_task(envelope)

        assert result["status"] == "success"
        assert result["intent"] == "RATE_SHEET_LOOKUP"
        assert result["result"]["jurisdiction"] == "CA"
        assert len(result["result"]["tax_brackets"]) == 2

    async def test_error_handling(self, financial_tax_agent):
        """Test error handling in process_task"""
        envelope = A2AEnvelope(intent="INVALID_INTENT", content={})

        financial_tax_agent.workflow.ainvoke = AsyncMock(
            side_effect=ValueError("Unsupported intent")
        )

        with pytest.raises(ValueError):
            await financial_tax_agent.process_task(envelope)

    async def test_route_by_intent(self, financial_tax_agent):
        """Test intent routing logic"""
        # Test each valid intent
        state = {"intent": "TAX_CALCULATION"}
        assert financial_tax_agent._route_by_intent(state) == "tax_calculation"

        state = {"intent": "FINANCIAL_ANALYSIS"}
        assert financial_tax_agent._route_by_intent(state) == "financial_analysis"

        state = {"intent": "TAX_COMPLIANCE_CHECK"}
        assert financial_tax_agent._route_by_intent(state) == "compliance_check"

        state = {"intent": "RATE_SHEET_LOOKUP"}
        assert financial_tax_agent._route_by_intent(state) == "rate_lookup"

        # Test invalid intent
        state = {"intent": "INVALID_INTENT"}
        with pytest.raises(ValueError):
            financial_tax_agent._route_by_intent(state)

    async def test_validate_data(self, financial_tax_agent):
        """Test data validation logic"""
        state = {"content": {"test": "data"}}
        result = await financial_tax_agent._validate_data(state)
        assert result["is_valid"] is True

    async def test_format_response(self, financial_tax_agent):
        """Test response formatting"""
        state = {"intent": "TAX_CALCULATION", "result": {"tax_liability": 5000}}

        result = await financial_tax_agent._format_response(state)

        assert result["response"]["status"] == "success"
        assert result["response"]["intent"] == "TAX_CALCULATION"
        assert result["response"]["result"]["tax_liability"] == 5000

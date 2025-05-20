"""Unit tests for Financial Tax Agent"""

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from agents.financial_tax import FinancialTaxAgent
from libs.a2a_adapter import A2AEnvelope


@pytest.fixture
def mock_pubsub():
    """Mock PubSub transport"""
    mock = AsyncMock()
    mock.publish_task = AsyncMock(return_value="test-message-id")
    mock.completed_topic_path = "projects/test/topics/completed"
    return mock


@pytest.fixture
def mock_supabase():
    """Mock Supabase transport"""
    mock = AsyncMock()
    mock.store_task = AsyncMock(return_value="test-task-id")
    mock.update_task_status = AsyncMock()
    mock.store_task_result = AsyncMock()
    mock.check_duplicate = AsyncMock(return_value=False)
    mock._pool = AsyncMock()
    mock._pool.acquire = AsyncMock()
    return mock


@pytest.fixture
def mock_policy():
    """Mock Policy middleware"""
    mock = AsyncMock()
    mock.apply_policies = AsyncMock(side_effect=lambda x: x)
    return mock


@pytest.fixture
def financial_tax_agent(mock_pubsub, mock_supabase, mock_policy):
    """Create Financial Tax Agent instance with mocked dependencies"""
    with patch("agents.financial_tax.agent.ChatOpenAI") as mock_openai:
        # Create a mock that actually inherits from the base class structure expected
        from typing import Any, Optional

        from langchain.schema.runnable import Runnable

        class MockLLM(Runnable):
            def invoke(self, input: Any, config: Optional[Any] = None, **kwargs: Any) -> Any:
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
    """Test suite for Financial Tax Agent"""

    @pytest.mark.asyncio
    async def test_agent_initialization(self, financial_tax_agent):
        """Test agent initializes with correct properties"""
        assert financial_tax_agent.name == "financial-tax-agent"
        assert financial_tax_agent.version == "1.0.0"
        assert "TAX_CALCULATION" in financial_tax_agent.supported_intents
        assert "FINANCIAL_ANALYSIS" in financial_tax_agent.supported_intents
        assert "TAX_COMPLIANCE_CHECK" in financial_tax_agent.supported_intents
        assert "RATE_SHEET_LOOKUP" in financial_tax_agent.supported_intents

    @pytest.mark.asyncio
    async def test_tax_calculation_processing(self, financial_tax_agent):
        """Test tax calculation processing"""
        # Create test envelope
        envelope = A2AEnvelope(
            intent="TAX_CALCULATION",
            content={
                "income": 100000,
                "deductions": {"mortgage_interest": 12000, "charitable": 5000},
                "credits": {"child_tax_credit": 2000},
                "jurisdiction": "US-CA",
                "tax_year": 2024,
                "entity_type": "individual",
                "additional_info": {},
            },
        )

        # Mock the chain result
        mock_result = MagicMock()
        mock_result.dict.return_value = {
            "gross_income": 100000,
            "total_deductions": 17000,
            "taxable_income": 83000,
            "tax_liability": 20000,
            "effective_tax_rate": 0.20,
            "marginal_tax_rate": 0.24,
            "credits_applied": 2000,
            "net_tax_due": 18000,
            "breakdown": {"federal": 15000, "state": 5000},
            "calculation_details": ["Standard deduction applied", "Tax credit applied"],
        }

        # Create a mock for the workflow
        mock_workflow = AsyncMock()
        mock_workflow.invoke.return_value = {
            "response": {
                "status": "success",
                "intent": "TAX_CALCULATION",
                "result": mock_result.dict.return_value,
            }
        }
        financial_tax_agent.workflow = mock_workflow

        # Call the process_task method
        result = await financial_tax_agent.process_task(envelope)

        assert result["status"] == "success"
        assert result["intent"] == "TAX_CALCULATION"
        assert "result" in result
        assert result["result"]["taxable_income"] == 83000
        assert result["result"]["net_tax_due"] == 18000

    @pytest.mark.asyncio
    async def test_financial_analysis_processing(self, financial_tax_agent):
        """Test financial analysis processing"""
        envelope = A2AEnvelope(
            intent="FINANCIAL_ANALYSIS",
            content={
                "financial_statements": {
                    "income_statement": {"revenue": 1000000, "expenses": 750000},
                    "balance_sheet": {"assets": 2000000, "liabilities": 800000},
                },
                "analysis_type": "profitability",
                "period": "Q4 2024",
                "industry": "technology",
                "custom_metrics": ["gross_margin", "debt_to_equity"],
            },
        )

        mock_result = MagicMock()
        mock_result.dict.return_value = {
            "summary": {"overall_health": "strong", "profitability": "above average"},
            "key_metrics": {"gross_margin": 0.25, "debt_to_equity": 0.4},
            "trends": {"revenue_growth": [0.05, 0.07, 0.06, 0.08]},
            "insights": ["Strong revenue growth", "Healthy profit margins"],
            "recommendations": [
                "Consider expanding operations",
                "Maintain current debt levels",
            ],
        }

        # Create a mock for the workflow
        mock_workflow = AsyncMock()
        mock_workflow.invoke.return_value = {
            "response": {
                "status": "success",
                "intent": "FINANCIAL_ANALYSIS",
                "result": mock_result.dict.return_value,
            }
        }
        financial_tax_agent.workflow = mock_workflow

        # Call the process_task method
        result = await financial_tax_agent.process_task(envelope)

        assert result["status"] == "success"
        assert result["intent"] == "FINANCIAL_ANALYSIS"
        assert "result" in result
        assert result["result"]["key_metrics"]["gross_margin"] == 0.25

    @pytest.mark.asyncio
    async def test_compliance_check_processing(self, financial_tax_agent):
        """Test compliance check processing"""
        envelope = A2AEnvelope(
            intent="TAX_COMPLIANCE_CHECK",
            content={
                "entity_type": "corporation",
                "transactions": [
                    {"type": "sale", "amount": 50000, "date": "2024-01-15"},
                    {"type": "expense", "amount": 10000, "date": "2024-01-20"},
                ],
                "jurisdiction": "US-NY",
                "tax_year": 2024,
                "compliance_areas": ["sales_tax", "corporate_income_tax"],
            },
        )

        mock_result = MagicMock()
        mock_result.dict.return_value = {
            "compliance_status": "partial_compliance",
            "issues_found": [
                {
                    "area": "sales_tax",
                    "severity": "medium",
                    "description": "Missing tax collection",
                }
            ],
            "recommendations": [
                "Register for sales tax collection",
                "File amended returns",
            ],
            "risk_level": "medium",
            "detailed_findings": {
                "sales_tax": "Non-compliant",
                "corporate_income_tax": "Compliant",
            },
        }

        # Create a mock for the workflow
        mock_workflow = AsyncMock()
        mock_workflow.invoke.return_value = {
            "response": {
                "status": "success",
                "intent": "TAX_COMPLIANCE_CHECK",
                "result": mock_result.dict.return_value,
            }
        }
        financial_tax_agent.workflow = mock_workflow

        # Call the process_task method
        result = await financial_tax_agent.process_task(envelope)

        assert result["status"] == "success"
        assert result["intent"] == "TAX_COMPLIANCE_CHECK"
        assert result["result"]["compliance_status"] == "partial_compliance"
        assert result["result"]["risk_level"] == "medium"

    @pytest.mark.asyncio
    async def test_rate_lookup_processing(self, financial_tax_agent):
        """Test tax rate lookup processing"""
        envelope = A2AEnvelope(
            intent="RATE_SHEET_LOOKUP",
            content={
                "jurisdiction": "US-CA",
                "tax_year": 2024,
                "entity_type": "individual",
                "income_level": 100000,
                "special_categories": ["capital_gains", "qualified_dividends"],
            },
        )

        mock_result = MagicMock()
        mock_result.dict.return_value = {
            "jurisdiction": "US-CA",
            "tax_year": 2024,
            "entity_type": "individual",
            "tax_brackets": [
                {"rate": 0.10, "min": 0, "max": 10000},
                {"rate": 0.12, "min": 10001, "max": 40000},
            ],
            "standard_deduction": 13850,
            "exemptions": {"personal": 4300},
            "special_rates": {"capital_gains": 0.15, "qualified_dividends": 0.15},
            "additional_info": {"state_rate": 0.093},
        }

        # Create a mock for the workflow
        mock_workflow = AsyncMock()
        mock_workflow.invoke.return_value = {
            "response": {
                "status": "success",
                "intent": "RATE_SHEET_LOOKUP",
                "result": mock_result.dict.return_value,
            }
        }
        financial_tax_agent.workflow = mock_workflow

        # Call the process_task method
        result = await financial_tax_agent.process_task(envelope)

        assert result["status"] == "success"
        assert result["intent"] == "RATE_SHEET_LOOKUP"
        assert result["result"]["standard_deduction"] == 13850
        assert result["result"]["special_rates"]["capital_gains"] == 0.15

    @pytest.mark.asyncio
    async def test_unsupported_intent_handling(self, financial_tax_agent):
        """Test handling of unsupported intent"""
        envelope = A2AEnvelope(intent="UNSUPPORTED_INTENT", content={"test": "data"})

        # Create a mock for the workflow that raises an exception
        mock_workflow = AsyncMock()
        mock_workflow.invoke.side_effect = ValueError("Unsupported intent: UNSUPPORTED_INTENT")
        financial_tax_agent.workflow = mock_workflow

        with pytest.raises(ValueError, match="Unsupported intent"):
            await financial_tax_agent.process_task(envelope)

    @pytest.mark.asyncio
    async def test_workflow_routing(self, financial_tax_agent):
        """Test the workflow correctly routes based on intent"""
        test_state = {"intent": "TAX_CALCULATION", "content": {"test": "data"}}

        # Test routing logic
        route = financial_tax_agent._route_by_intent(test_state)
        assert route == "tax_calculation"

        test_state["intent"] = "FINANCIAL_ANALYSIS"
        route = financial_tax_agent._route_by_intent(test_state)
        assert route == "financial_analysis"

    @pytest.mark.asyncio
    async def test_error_handling(self, financial_tax_agent):
        """Test error handling in process_task"""
        envelope = A2AEnvelope(
            intent="TAX_CALCULATION",
            content={"invalid": "data"},  # Missing required fields
        )

        with pytest.raises(Exception):
            await financial_tax_agent.process_task(envelope)

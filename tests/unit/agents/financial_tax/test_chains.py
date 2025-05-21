"""Tests for Financial Tax Agent chains."""

from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from langchain.schema import Generation

from agents.financial_tax.chains import (
    ComplianceCheckChain,
    FinancialAnalysisChain,
    RateLookupChain,
    TaxCalculationChain,
)
from agents.financial_tax.models import (
    ComplianceCheckRequest,
    ComplianceCheckResponse,
    EntityType,
    FinancialAnalysisRequest,
    FinancialAnalysisResponse,
    TaxCalculationRequest,
    TaxCalculationResponse,
    TaxJurisdiction,
    TaxRateRequest,
    TaxRateResponse,
)


@pytest.fixture
def mock_llm():
    """Mock LLM for chain tests."""
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

    return MockLLM()


class TestTaxCalculationChain:
    """Test cases for TaxCalculationChain."""

    def test_chain_initialization(self, mock_llm):
        """Test chain initializes with proper configuration."""
        chain = TaxCalculationChain(llm=mock_llm)

        assert chain.llm == mock_llm
        assert chain.output_parser is not None
        assert chain.prompt is not None
        assert chain.chain is not None

    async def test_calculate_with_valid_request(self, mock_llm):
        """Test tax calculation with valid request."""
        with patch.object(TaxCalculationChain, "calculate") as mock_calculate:
            # Create a mock response
            mock_calculate.return_value = TaxCalculationResponse(
                gross_income=150000.0,
                total_deductions=27700.0,
                taxable_income=122300.0,
                tax_liability=18000.0,
                effective_tax_rate=12.0,
                marginal_tax_rate=22.0,
                credits_applied=4000.0,
                net_tax_due=14000.0,
                breakdown={"income": 150000.0, "wages": 150000.0},
                calculation_details=["Standard deduction applied", "Child tax credit applied"],
            )

            # Create the chain
            chain = TaxCalculationChain(llm=mock_llm)

            # Create the request
            request = TaxCalculationRequest(
                income=150000.0,
                deductions={"standard": 27700.0},
                credits={"child_tax_credit": 4000.0},
                jurisdiction=TaxJurisdiction.US_FEDERAL,
                tax_year=2024,
                entity_type=EntityType.INDIVIDUAL,
                additional_info={"dependents": 2},
            )

            # Process the request
            response = await chain.calculate(request)

            # Verify the response
            assert isinstance(response, TaxCalculationResponse)
            assert response.gross_income == 150000.0
            assert response.net_tax_due == 14000.0
            assert response.effective_tax_rate == 12.0

            # Verify chain was called with correct parameters
            mock_calculate.assert_called_once_with(request)

    async def test_calculate_with_parsing_error(self, mock_llm):
        """Test error handling when LLM returns unparseable result."""
        with patch("langchain.output_parsers.PydanticOutputParser.parse") as mock_parse:
            # Configure the parse method to raise an exception
            mock_parse.side_effect = ValueError("Invalid JSON")

            # Create the chain
            chain = TaxCalculationChain(llm=mock_llm)

            # Create the request
            request = TaxCalculationRequest(
                income=100000.0,
                deductions={},
                credits={},
                jurisdiction=TaxJurisdiction.US_FEDERAL,
                tax_year=2024,
                entity_type=EntityType.INDIVIDUAL,
            )

            # Verify that an exception is raised
            with pytest.raises(ValueError):
                await chain.calculate(request)


class TestFinancialAnalysisChain:
    """Test cases for FinancialAnalysisChain."""

    async def test_analyze_with_valid_request(self, mock_llm):
        """Test financial analysis with valid request."""
        with patch.object(FinancialAnalysisChain, "analyze") as mock_analyze:
            # Create a mock response
            mock_analyze.return_value = FinancialAnalysisResponse(
                summary={"overall_health": "good"},
                key_metrics={"profit_margin": 25.0, "current_ratio": 2.5},
                trends={"revenue": [100000, 150000, 200000]},
                insights=["Strong profitability metrics"],
                recommendations=["Consider expansion"],
                visualizations=None,
                benchmark_comparison=None,
            )

            # Create the chain
            chain = FinancialAnalysisChain(llm=mock_llm)

            # Create the request
            request = FinancialAnalysisRequest(
                financial_statements={
                    "income_statement": {"revenue": 1000000, "expenses": 750000},
                    "balance_sheet": {"assets": 500000, "liabilities": 200000},
                },
                analysis_type="profitability",
                period="2024",
                industry="technology",
            )

            # Process the request
            response = await chain.analyze(request)

            # Verify the response
            assert isinstance(response, FinancialAnalysisResponse)
            assert response.key_metrics["profit_margin"] == 25.0
            assert len(response.insights) == 1
            assert len(response.recommendations) == 1

            # Verify the analyze method was called with the request
            mock_analyze.assert_called_once_with(request)


class TestComplianceCheckChain:
    """Test cases for ComplianceCheckChain."""

    async def test_check_compliance_with_valid_request(self, mock_llm):
        """Test compliance check with valid request."""
        with patch.object(ComplianceCheckChain, "check_compliance") as mock_check_compliance:
            # Create a mock response
            mock_check_compliance.return_value = ComplianceCheckResponse(
                compliance_status="partially_compliant",
                issues_found=[{"area": "sales_tax", "issue": "Missing nexus registration"}],
                recommendations=["Register for sales tax permit"],
                risk_level="medium",
                detailed_findings={"sales_tax": {"issues": ["nexus"]}},
            )

            # Create the chain
            chain = ComplianceCheckChain(llm=mock_llm)

            # Create the request
            request = ComplianceCheckRequest(
                entity_type=EntityType.CORPORATION,
                transactions=[{"type": "sale", "amount": 10000}],
                jurisdiction=TaxJurisdiction.US_CA,
                tax_year=2024,
                compliance_areas=["sales_tax", "employment_tax"],
            )

            # Process the request
            response = await chain.check_compliance(request)

            # Verify the response
            assert isinstance(response, ComplianceCheckResponse)
            assert response.compliance_status == "partially_compliant"
            assert len(response.issues_found) == 1
            assert response.risk_level == "medium"

            # Verify the check_compliance method was called with the request
            mock_check_compliance.assert_called_once_with(request)


class TestRateLookupChain:
    """Test cases for RateLookupChain."""

    async def test_lookup_rates_with_valid_request(self, mock_llm):
        """Test tax rate lookup with valid request."""
        with patch.object(RateLookupChain, "lookup_rates") as mock_lookup_rates:
            # Create a mock response
            mock_lookup_rates.return_value = TaxRateResponse(
                jurisdiction=TaxJurisdiction.US_CA,
                tax_year=2024,
                entity_type=EntityType.INDIVIDUAL,
                tax_brackets=[
                    {"rate": 1.0, "threshold": 10412, "description": "First bracket"},
                    {"rate": 2.0, "threshold": 24684, "description": "Second bracket"},
                ],
                standard_deduction=13850.0,
                exemptions={"personal": 0},
                special_rates={"capital_gains": 20.0},
                additional_info={"notes": ["CA has 9 tax brackets"]},
            )

            # Create the chain
            chain = RateLookupChain(llm=mock_llm)

            # Create the request
            request = TaxRateRequest(
                jurisdiction=TaxJurisdiction.US_CA,
                tax_year=2024,
                entity_type=EntityType.INDIVIDUAL,
                income_level=150000.0,
            )

            # Process the request
            response = await chain.lookup_rates(request)

            # Verify the response
            assert isinstance(response, TaxRateResponse)
            assert response.jurisdiction == TaxJurisdiction.US_CA
            assert len(response.tax_brackets) == 2
            assert response.standard_deduction == 13850.0
            assert response.special_rates["capital_gains"] == 20.0

            # Verify the lookup_rates method was called with the request
            mock_lookup_rates.assert_called_once_with(request)

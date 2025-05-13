"""Unit tests for Financial Tax Agent chains"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch

from agents.financial_tax.chains import (
    TaxCalculationChain,
    FinancialAnalysisChain,
    ComplianceCheckChain,
    RateLookupChain,
)
from agents.financial_tax.models import (
    TaxCalculationRequest,
    FinancialAnalysisRequest,
    ComplianceCheckRequest,
    TaxRateRequest,
    TaxJurisdiction,
    EntityType,
)


@pytest.fixture
def mock_llm():
    """Mock LLM for testing chains."""
    with patch("agents.financial_tax.chains.ChatOpenAI") as mock:
        llm_instance = MagicMock()
        mock.return_value = llm_instance
        yield llm_instance


class TestTaxCalculationChain:
    """Test suite for TaxCalculationChain."""

    @pytest.fixture
    def tax_calc_chain(self, mock_llm):
        """Create TaxCalculationChain instance."""
        return TaxCalculationChain(llm=mock_llm)

    @pytest.mark.asyncio
    async def test_calculate_success(self, tax_calc_chain):
        """Test successful tax calculation."""
        # Mock the chain result
        mock_result = """
        {
            "gross_income": 100000,
            "total_deductions": 17000,
            "taxable_income": 83000,
            "tax_liability": 20000,
            "effective_tax_rate": 0.20,
            "marginal_tax_rate": 0.24,
            "credits_applied": 2000,
            "net_tax_due": 18000,
            "breakdown": {"federal": 15000, "state": 5000},
            "calculation_details": ["Standard deduction applied", "Tax credit applied"]
        }
        """

        tax_calc_chain.chain.arun = AsyncMock(return_value=mock_result)

        request = TaxCalculationRequest(
            income=100000,
            deductions={"mortgage": 12000},
            credits={"child_credit": 2000},
            jurisdiction=TaxJurisdiction.US_CA,
            tax_year=2024,
            entity_type=EntityType.INDIVIDUAL,
        )

        with patch.object(tax_calc_chain.output_parser, "parse") as mock_parse:
            mock_parse.return_value = MagicMock(
                gross_income=100000,
                total_deductions=17000,
                taxable_income=83000,
                tax_liability=20000,
                effective_tax_rate=0.20,
                marginal_tax_rate=0.24,
                credits_applied=2000,
                net_tax_due=18000,
                breakdown={"federal": 15000, "state": 5000},
                calculation_details=["Standard deduction applied", "Tax credit applied"],
            )

            result = await tax_calc_chain.calculate(request)

            assert result.gross_income == 100000
            assert result.net_tax_due == 18000
            assert result.effective_tax_rate == 0.20


class TestFinancialAnalysisChain:
    """Test suite for FinancialAnalysisChain."""

    @pytest.fixture
    def analysis_chain(self, mock_llm):
        """Create FinancialAnalysisChain instance."""
        return FinancialAnalysisChain(llm=mock_llm)

    @pytest.mark.asyncio
    async def test_analyze_success(self, analysis_chain):
        """Test successful financial analysis."""
        mock_result = """
        {
            "summary": {"overall_health": "strong", "profitability": "above average"},
            "key_metrics": {"gross_margin": 0.25, "debt_to_equity": 0.4},
            "trends": {"revenue_growth": [0.05, 0.07, 0.06, 0.08]},
            "insights": ["Strong revenue growth", "Healthy profit margins"],
            "recommendations": ["Consider expanding operations", "Maintain current debt levels"],
            "visualizations": null,
            "benchmark_comparison": {"industry_avg": 0.20}
        }
        """

        analysis_chain.chain.arun = AsyncMock(return_value=mock_result)

        request = FinancialAnalysisRequest(
            financial_statements={
                "income_statement": {"revenue": 1000000, "expenses": 750000},
                "balance_sheet": {"assets": 2000000, "liabilities": 800000},
            },
            analysis_type="profitability",
            period="Q4 2024",
            industry="technology",
        )

        with patch.object(analysis_chain.output_parser, "parse") as mock_parse:
            mock_parse.return_value = MagicMock(
                summary={"overall_health": "strong", "profitability": "above average"},
                key_metrics={"gross_margin": 0.25, "debt_to_equity": 0.4},
                trends={"revenue_growth": [0.05, 0.07, 0.06, 0.08]},
                insights=["Strong revenue growth", "Healthy profit margins"],
                recommendations=["Consider expanding operations", "Maintain current debt levels"],
                visualizations=None,
                benchmark_comparison={"industry_avg": 0.20},
            )

            result = await analysis_chain.analyze(request)

            assert result.key_metrics["gross_margin"] == 0.25
            assert len(result.insights) == 2
            assert "Strong revenue growth" in result.insights


class TestComplianceCheckChain:
    """Test suite for ComplianceCheckChain."""

    @pytest.fixture
    def compliance_chain(self, mock_llm):
        """Create ComplianceCheckChain instance."""
        return ComplianceCheckChain(llm=mock_llm)

    @pytest.mark.asyncio
    async def test_check_compliance_success(self, compliance_chain):
        """Test successful compliance check."""
        mock_result = """
        {
            "compliance_status": "partial_compliance",
            "issues_found": [
                {"area": "sales_tax", "severity": "high", "description": "Missing tax collection"}
            ],
            "recommendations": ["Register for sales tax collection", "File amended returns"],
            "risk_level": "medium",
            "detailed_findings": {"sales_tax": "Non-compliant", "income_tax": "Compliant"}
        }
        """

        compliance_chain.chain.arun = AsyncMock(return_value=mock_result)

        request = ComplianceCheckRequest(
            entity_type=EntityType.CORPORATION,
            transactions=[{"type": "sale", "amount": 50000, "date": "2024-01-15"}],
            jurisdiction=TaxJurisdiction.US_NY,
            tax_year=2024,
            compliance_areas=["sales_tax", "income_tax"],
        )

        with patch.object(compliance_chain.output_parser, "parse") as mock_parse:
            mock_parse.return_value = MagicMock(
                compliance_status="partial_compliance",
                issues_found=[
                    {
                        "area": "sales_tax",
                        "severity": "high",
                        "description": "Missing tax collection",
                    }
                ],
                recommendations=["Register for sales tax collection", "File amended returns"],
                risk_level="medium",
                detailed_findings={"sales_tax": "Non-compliant", "income_tax": "Compliant"},
            )

            result = await compliance_chain.check_compliance(request)

            assert result.compliance_status == "partial_compliance"
            assert result.risk_level == "medium"
            assert len(result.issues_found) == 1


class TestRateLookupChain:
    """Test suite for RateLookupChain."""

    @pytest.fixture
    def rate_lookup_chain(self, mock_llm):
        """Create RateLookupChain instance."""
        return RateLookupChain(llm=mock_llm)

    @pytest.mark.asyncio
    async def test_lookup_rates_success(self, rate_lookup_chain):
        """Test successful tax rate lookup."""
        mock_result = """
        {
            "jurisdiction": "US-CA",
            "tax_year": 2024,
            "entity_type": "individual",
            "tax_brackets": [
                {"rate": 0.10, "min": 0, "max": 10000},
                {"rate": 0.12, "min": 10001, "max": 40000}
            ],
            "standard_deduction": 13850,
            "exemptions": {"personal": 4300},
            "special_rates": {"capital_gains": 0.15},
            "additional_info": {"state_rate": 0.093}
        }
        """

        rate_lookup_chain.chain.arun = AsyncMock(return_value=mock_result)

        request = TaxRateRequest(
            jurisdiction=TaxJurisdiction.US_CA,
            tax_year=2024,
            entity_type=EntityType.INDIVIDUAL,
            income_level=100000,
        )

        with patch.object(rate_lookup_chain.output_parser, "parse") as mock_parse:
            mock_parse.return_value = MagicMock(
                jurisdiction="US-CA",
                tax_year=2024,
                entity_type="individual",
                tax_brackets=[
                    {"rate": 0.10, "min": 0, "max": 10000},
                    {"rate": 0.12, "min": 10001, "max": 40000},
                ],
                standard_deduction=13850,
                exemptions={"personal": 4300},
                special_rates={"capital_gains": 0.15},
                additional_info={"state_rate": 0.093},
            )

            result = await rate_lookup_chain.lookup_rates(request)

            assert result.jurisdiction == "US-CA"
            assert result.standard_deduction == 13850
            assert len(result.tax_brackets) == 2
            assert result.special_rates["capital_gains"] == 0.15

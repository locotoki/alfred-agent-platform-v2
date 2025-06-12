"""Financial Tax Agent module.

This module has been moved to services.agent_bizops.workflows.finance.
This stub is kept for backward compatibility.
"""

# Re-export from the new location for backward compatibility
try:
    from services.agent_bizops.workflows.finance.agent import FinancialTaxAgentLFfrom services.agent_bizops.workflows.finance.chains import (LF    LF,LF    ComplianceCheckChain,LF    FinancialAnalysisChain,LF    RateLookupChain,LF    TaxCalculationChain,LF)LFfrom services.agent_bizops.workflows.finance.models import (LF    LF,LF    ComplianceCheckRequest,LF    ComplianceCheckResponse,LF    EntityType,LF    FinancialAnalysisRequest,LF    FinancialAnalysisResponse,LF    TaxCalculationRequest,LF    TaxCalculationResponse,LF    TaxJurisdiction,LF    TaxRateRequest,LF    TaxRateResponse,LF)LF

    __all__ = [
        "FinancialTaxAgent",
        "ComplianceCheckChain",
        "FinancialAnalysisChain",
        "RateLookupChain",
        "TaxCalculationChain",
        "ComplianceCheckRequest",
        "ComplianceCheckResponse",
        "EntityType",
        "FinancialAnalysisRequest",
        "FinancialAnalysisResponse",
        "TaxCalculationRequest",
        "TaxCalculationResponse",
        "TaxJurisdiction",
        "TaxRateRequest",
        "TaxRateResponse",
    ]
except ImportError:
    # If the new location is not available, provide empty module
    pass

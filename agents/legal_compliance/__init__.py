"""Legal Compliance Agent module.

This module has been moved to services.agent_bizops.workflows.legal.
This stub is kept for backward compatibility.
"""

# Re-export from the new location for backward compatibility
try:
    from services.agent_bizops.workflows.legal.agent import LegalComplianceAgentLFfrom services.agent_bizops.workflows.legal.chains import (LF    LF,LF    ComplianceCheckChain,LF    LegalAnalysisChain,LF    RegulationLookupChain,LF)LFfrom services.agent_bizops.workflows.legal.models import (LF    LF,LF    ComplianceCheckRequest,LF    ComplianceCheckResponse,LF    LegalAnalysisRequest,LF    LegalAnalysisResponse,LF    RegulationLookupRequest,LF    RegulationLookupResponse,LF)LF

    __all__ = [
        "LegalComplianceAgent",
        "ComplianceCheckChain",
        "LegalAnalysisChain",
        "RegulationLookupChain",
        "ComplianceCheckRequest",
        "ComplianceCheckResponse",
        "LegalAnalysisRequest",
        "LegalAnalysisResponse",
        "RegulationLookupRequest",
        "RegulationLookupResponse",
    ]
except ImportError:
    # If the new location is not available, provide empty module
    pass

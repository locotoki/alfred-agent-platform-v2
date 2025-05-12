#!/bin/bash
set -e

echo "Creating financial-tax and legal-compliance stubs in their containers..."

# Create stubs for financial-tax agent
docker exec agent-financial sh -c "mkdir -p /app/agents/financial_tax"
docker exec agent-financial sh -c "echo '\"\"\"Stub implementation of FinancialTaxAgent.\"\"\"

class FinancialTaxAgent:
    def __init__(self, pubsub_transport, supabase_transport, policy_middleware):
        self.pubsub_transport = pubsub_transport
        self.supabase_transport = supabase_transport
        self.policy_middleware = policy_middleware
        self.is_running = False
        self.supported_intents = [\"TAX_CALCULATION\", \"FINANCIAL_ANALYSIS\", \"TAX_COMPLIANCE_CHECK\", \"RATE_SHEET_LOOKUP\"]
        
    async def start(self):
        self.is_running = True
        print(\"Starting FinancialTaxAgent...\")
        
    async def stop(self):
        self.is_running = False
        print(\"Stopping FinancialTaxAgent...\")
        
class TaxCalculationRequest:
    @staticmethod
    def dict():
        return {}
        
class FinancialAnalysisRequest:
    @staticmethod
    def dict():
        return {}
        
class ComplianceCheckRequest:
    @staticmethod
    def dict():
        return {}
        
class TaxRateRequest:
    def __init__(self, jurisdiction, tax_year, entity_type):
        self.jurisdiction = jurisdiction
        self.tax_year = tax_year
        self.entity_type = entity_type
        
    def dict(self):
        return {
            \"jurisdiction\": self.jurisdiction,
            \"tax_year\": self.tax_year,
            \"entity_type\": self.entity_type
        }
' > /app/agents/financial_tax/__init__.py"

# Create stubs for legal-compliance agent
docker exec agent-legal sh -c "mkdir -p /app/agents/legal_compliance"
docker exec agent-legal sh -c "echo '\"\"\"Stub implementation of LegalComplianceAgent.\"\"\"

class LegalComplianceAgent:
    def __init__(self, pubsub_transport, supabase_transport, policy_middleware):
        self.pubsub_transport = pubsub_transport
        self.supabase_transport = supabase_transport
        self.policy_middleware = policy_middleware
        self.is_running = False
        self.supported_intents = [\"COMPLIANCE_AUDIT\", \"DOCUMENT_ANALYSIS\", \"REGULATION_CHECK\", \"CONTRACT_REVIEW\"]
        
    async def start(self):
        self.is_running = True
        print(\"Starting LegalComplianceAgent...\")
        
    async def stop(self):
        self.is_running = False
        print(\"Stopping LegalComplianceAgent...\")
        
class ComplianceAuditRequest:
    @staticmethod
    def dict():
        return {}
        
class DocumentAnalysisRequest:
    @staticmethod
    def dict():
        return {}
        
class RegulationCheckRequest:
    @staticmethod
    def dict():
        return {}
        
class ContractReviewRequest:
    @staticmethod
    def dict():
        return {}
' > /app/agents/legal_compliance/__init__.py"

echo "Restarting services..."
docker-compose -f docker-compose.unified.yml restart agent-financial agent-legal

echo "Done. Check services status with: docker ps | grep agent"
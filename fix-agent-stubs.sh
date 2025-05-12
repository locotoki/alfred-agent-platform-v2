#!/bin/bash

# Create directories for the stubs
echo "Creating agent stub directories..."
mkdir -p /home/locotoki/projects/alfred-agent-platform-v2/agents_stubs/financial_tax
mkdir -p /home/locotoki/projects/alfred-agent-platform-v2/agents_stubs/legal_compliance

# Create financial-tax agent stubs
echo "Creating financial-tax agent stubs..."
cat > /home/locotoki/projects/alfred-agent-platform-v2/agents_stubs/financial_tax/__init__.py << 'EOL'
"""Stub implementation of FinancialTaxAgent."""

class FinancialTaxAgent:
    def __init__(self, pubsub_transport, supabase_transport, policy_middleware):
        self.pubsub_transport = pubsub_transport
        self.supabase_transport = supabase_transport
        self.policy_middleware = policy_middleware
        self.is_running = False
        self.supported_intents = ["TAX_CALCULATION", "FINANCIAL_ANALYSIS", "TAX_COMPLIANCE_CHECK", "RATE_SHEET_LOOKUP"]
        
    async def start(self):
        self.is_running = True
        print("Starting FinancialTaxAgent...")
        
    async def stop(self):
        self.is_running = False
        print("Stopping FinancialTaxAgent...")
        
    async def add_context(self, task_id, context):
        """Add context to the agent for a specific task."""
        print(f"Adding context for task {task_id}")
        return True
        
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
            "jurisdiction": self.jurisdiction,
            "tax_year": self.tax_year,
            "entity_type": self.entity_type
        }
EOL

# Create legal-compliance agent stubs
echo "Creating legal-compliance agent stubs..."
cat > /home/locotoki/projects/alfred-agent-platform-v2/agents_stubs/legal_compliance/__init__.py << 'EOL'
"""Stub implementation of LegalComplianceAgent."""

class LegalComplianceAgent:
    def __init__(self, pubsub_transport, supabase_transport, policy_middleware):
        self.pubsub_transport = pubsub_transport
        self.supabase_transport = supabase_transport
        self.policy_middleware = policy_middleware
        self.is_running = False
        self.supported_intents = ["COMPLIANCE_AUDIT", "DOCUMENT_ANALYSIS", "REGULATION_CHECK", "CONTRACT_REVIEW"]
        
    async def start(self):
        self.is_running = True
        print("Starting LegalComplianceAgent...")
        
    async def stop(self):
        self.is_running = False
        print("Stopping LegalComplianceAgent...")
        
    async def add_context(self, task_id, context):
        """Add context to the agent for a specific task."""
        print(f"Adding context for task {task_id}")
        return True
        
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
EOL

echo "Stubs created successfully! Now update docker-compose.unified.yml to mount these directories:"
echo "- ./agents_stubs/financial_tax:/app/agents/financial_tax for agent-financial"
echo "- ./agents_stubs/legal_compliance:/app/agents/legal_compliance for agent-legal"
"""Stub implementation of FinancialTaxAgent."""

from typing import List, Dict, Any, Optional
from pydantic import BaseModel

class TaxCalculationRequest(BaseModel):
    jurisdiction: str
    tax_year: int
    entity_type: str
    income: float
    deductions: Optional[List[Dict[str, Any]]] = None
    dependents: Optional[int] = None
    
    def dict(self):
        return {
            "jurisdiction": self.jurisdiction,
            "tax_year": self.tax_year,
            "entity_type": self.entity_type,
            "income": self.income,
            "deductions": self.deductions or [],
            "dependents": self.dependents or 0
        }

class FinancialAnalysisRequest(BaseModel):
    data: Dict[str, Any]
    statement_type: Optional[str] = None
    industry: Optional[str] = None
    
    def dict(self):
        return {
            "data": self.data,
            "statement_type": self.statement_type,
            "industry": self.industry
        }

class ComplianceCheckRequest(BaseModel):
    transactions: List[Dict[str, Any]]
    jurisdictions: List[str]
    tax_year: int
    
    def dict(self):
        return {
            "transactions": self.transactions,
            "jurisdictions": self.jurisdictions,
            "tax_year": self.tax_year
        }

class TaxRateRequest(BaseModel):
    jurisdiction: str
    tax_year: int
    entity_type: str
    
    def dict(self):
        return {
            "jurisdiction": self.jurisdiction,
            "tax_year": self.tax_year,
            "entity_type": self.entity_type
        }

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
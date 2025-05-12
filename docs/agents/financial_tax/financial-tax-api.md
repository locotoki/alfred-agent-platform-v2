# Financial-Tax Agent API Reference

*Last Updated: 2025-05-12*  
*Owner: Financial-Tax Team*  
*Status: Draft*

## Overview

This document provides a comprehensive reference for the Financial-Tax Agent API, including endpoints, request/response formats, authentication, and examples.

## Base URL

The Financial-Tax Agent API is accessible at:

```
http://agent-financial:9003/api/v1
```

For internal agent-to-agent communication within the platform:

```
http://agent-financial:9003/a2a/v1
```

## Authentication

The API uses the following authentication methods:

- **API Key Authentication**: For direct API access
- **JWT Authentication**: For authenticated user sessions
- **A2A Authentication**: For agent-to-agent communication

### API Key Authentication

API keys must be included in the `X-API-Key` header:

```
X-API-Key: your-api-key-here
```

### JWT Authentication

JWT tokens must be included in the `Authorization` header:

```
Authorization: Bearer your-jwt-token-here
```

## Rate Limiting

The API enforces the following rate limits:

- **External Access**: 100 requests per minute
- **Internal Platform Access**: 500 requests per minute

## Endpoints

### Tax Estimation

#### Calculate Tax Estimate

```
POST /tax/estimate
```

Calculate estimated tax liability based on provided financial data.

**Request Body:**

```json
{
  "income": {
    "employment": 85000.00,
    "self_employment": 12000.00,
    "investments": 3500.00,
    "rental": 0.00,
    "other": 500.00
  },
  "deductions": {
    "retirement_contributions": 6000.00,
    "health_insurance": 3200.00,
    "mortgage_interest": 8500.00,
    "charitable_donations": 2000.00,
    "other": 1500.00
  },
  "tax_year": 2025,
  "filing_status": "married_joint",
  "dependents": 2,
  "state": "CA"
}
```

**Response:**

```json
{
  "request_id": "tax-est-123e4567-e89b-12d3-a456-426614174000",
  "summary": {
    "total_income": 101000.00,
    "adjusted_gross_income": 90300.00,
    "taxable_income": 65800.00,
    "federal_tax": 7296.00,
    "state_tax": 4830.00,
    "total_tax": 12126.00,
    "effective_tax_rate": 12.01
  },
  "details": {
    "federal": {
      "ordinary_income_tax": 6496.00,
      "self_employment_tax": 1800.00,
      "investment_income_tax": 0.00,
      "total": 7296.00
    },
    "state": {
      "income_tax": 4830.00,
      "total": 4830.00
    },
    "deductions": {
      "standard_deduction": 25900.00,
      "itemized_deduction": 21200.00,
      "selected": "standard",
      "credits": 4000.00
    }
  },
  "recommendations": [
    {
      "type": "retirement",
      "description": "Increasing retirement contributions by $4000 would reduce tax liability by approximately $880",
      "impact": 880.00
    },
    {
      "type": "deduction",
      "description": "Consider bunching charitable donations to exceed standard deduction threshold",
      "impact": 320.00
    }
  ]
}
```

#### Get Tax Estimate Status

```
GET /tax/estimate/{request_id}
```

Retrieve the status or result of a previously submitted tax estimate request.

**Parameters:**

- `request_id` (path parameter): The unique identifier from the estimate request

**Response:**

```json
{
  "request_id": "tax-est-123e4567-e89b-12d3-a456-426614174000",
  "status": "completed",
  "submitted_at": "2025-05-12T14:23:15Z",
  "completed_at": "2025-05-12T14:23:18Z",
  "result": {
    "summary": {
      "total_income": 101000.00,
      "adjusted_gross_income": 90300.00,
      "taxable_income": 65800.00,
      "federal_tax": 7296.00,
      "state_tax": 4830.00,
      "total_tax": 12126.00,
      "effective_tax_rate": 12.01
    },
    "details": { /* ... Same as above ... */ }
  }
}
```

### Financial Analysis

#### Generate Financial Report

```
POST /finance/report
```

Generate a comprehensive financial analysis report.

**Request Body:**

```json
{
  "transactions": [
    {
      "date": "2025-04-15",
      "amount": -1250.00,
      "category": "housing",
      "description": "Monthly rent payment"
    },
    {
      "date": "2025-04-16",
      "amount": -85.42,
      "category": "utilities",
      "description": "Electric bill"
    },
    {
      "date": "2025-04-18",
      "amount": 3200.00,
      "category": "income",
      "description": "Salary deposit"
    }
    // ... additional transactions ...
  ],
  "balance_history": [
    {
      "date": "2025-04-01",
      "checking": 5430.21,
      "savings": 12500.00,
      "investments": 45800.00,
      "credit_cards": -3200.00
    },
    {
      "date": "2025-05-01",
      "checking": 5880.45,
      "savings": 12700.00,
      "investments": 47200.00,
      "credit_cards": -2800.00
    }
  ],
  "report_type": "monthly",
  "time_period": {
    "start_date": "2025-04-01",
    "end_date": "2025-04-30"
  },
  "include_forecasting": true,
  "forecasting_months": 3
}
```

**Response:**

```json
{
  "report_id": "fin-rep-123e4567-e89b-12d3-a456-426614174000",
  "summary": {
    "total_income": 6400.00,
    "total_expenses": 4250.32,
    "net_cash_flow": 2149.68,
    "savings_rate": 33.59,
    "top_expense_category": "housing",
    "top_expense_amount": 1250.00
  },
  "expense_breakdown": {
    "housing": 1250.00,
    "utilities": 320.12,
    "groceries": 480.20,
    "transportation": 350.00,
    "dining": 280.00,
    "entertainment": 150.00,
    "other": 1420.00
  },
  "metrics": {
    "debt_to_income_ratio": 0.32,
    "emergency_fund_months": 2.94,
    "savings_growth_rate": 3.2,
    "investment_performance": 5.8
  },
  "recommendations": [
    {
      "category": "emergency_fund",
      "description": "Increase emergency fund by $1800 to reach 3-month target",
      "priority": "high"
    },
    {
      "category": "expense_reduction",
      "description": "Dining expenses are 15% higher than previous month",
      "priority": "medium"
    }
  ],
  "forecasting": {
    "projected_savings": [
      { "month": "2025-05", "amount": 15200.00 },
      { "month": "2025-06", "amount": 17400.00 },
      { "month": "2025-07", "amount": 19600.00 }
    ],
    "projected_net_worth": [
      { "month": "2025-05", "amount": 62980.45 },
      { "month": "2025-06", "amount": 65250.00 },
      { "month": "2025-07", "amount": 67600.00 }
    ]
  }
}
```

#### Categorize Expenses

```
POST /finance/categorize
```

Automatically categorize financial transactions.

**Request Body:**

```json
{
  "transactions": [
    {
      "date": "2025-05-10",
      "amount": -42.67,
      "description": "WHOLEFDS MPK 10038",
      "merchant": "Whole Foods"
    },
    {
      "date": "2025-05-10",
      "amount": -35.00,
      "description": "SHELL OIL 57442931",
      "merchant": "Shell"
    },
    {
      "date": "2025-05-11",
      "amount": -128.34,
      "description": "AMZN Mktp US*1A23BC4DE",
      "merchant": "Amazon"
    }
  ],
  "use_custom_rules": true
}
```

**Response:**

```json
{
  "categorized_transactions": [
    {
      "date": "2025-05-10",
      "amount": -42.67,
      "description": "WHOLEFDS MPK 10038",
      "merchant": "Whole Foods",
      "category": "groceries",
      "confidence": 0.98
    },
    {
      "date": "2025-05-10",
      "amount": -35.00,
      "description": "SHELL OIL 57442931",
      "merchant": "Shell",
      "category": "transportation",
      "subcategory": "fuel",
      "confidence": 0.99
    },
    {
      "date": "2025-05-11",
      "amount": -128.34,
      "description": "AMZN Mktp US*1A23BC4DE",
      "merchant": "Amazon",
      "category": "shopping",
      "subcategory": "online",
      "confidence": 0.85,
      "alternative_categories": [
        {"category": "household", "confidence": 0.72},
        {"category": "gifts", "confidence": 0.43}
      ]
    }
  ],
  "summary": {
    "total_transactions": 3,
    "categorized": 3,
    "uncategorized": 0,
    "low_confidence": 0
  }
}
```

### Tax Compliance

#### Verify Tax Compliance

```
POST /tax/compliance/verify
```

Verify compliance of tax-related data with applicable regulations.

**Request Body:**

```json
{
  "tax_year": 2024,
  "jurisdiction": "US",
  "filing_status": "married_joint",
  "income_sources": [
    {
      "type": "w2",
      "income": 95000.00,
      "withholding": 18500.00
    },
    {
      "type": "1099",
      "income": 15000.00,
      "withholding": 0.00
    },
    {
      "type": "investment",
      "income": 3200.00,
      "withholding": 450.00
    }
  ],
  "deductions": [
    {
      "type": "mortgage_interest",
      "amount": 9500.00
    },
    {
      "type": "charitable",
      "amount": 2500.00
    },
    {
      "type": "hsa_contribution",
      "amount": 3650.00
    }
  ],
  "credits": [
    {
      "type": "child_tax_credit",
      "amount": 4000.00
    }
  ]
}
```

**Response:**

```json
{
  "compliance_id": "comp-123e4567-e89b-12d3-a456-426614174000",
  "overall_compliance": "compliant",
  "compliance_score": 96,
  "findings": [
    {
      "type": "warning",
      "category": "self_employment_tax",
      "description": "No estimated tax payments found for 1099 income",
      "recommendation": "Consider making estimated tax payments for self-employment income",
      "reference": "IRC § 6654",
      "severity": "medium"
    },
    {
      "type": "info",
      "category": "retirement_planning",
      "description": "No IRA or 401(k) contributions detected",
      "recommendation": "Consider tax-advantaged retirement contributions",
      "severity": "low"
    }
  ],
  "verification_details": {
    "rules_checked": 134,
    "rules_passed": 129,
    "rules_warned": 5,
    "rules_failed": 0
  }
}
```

## A2A Protocol Endpoints

The Financial-Tax Agent implements the Agent-to-Agent (A2A) protocol for inter-agent communication.

### Process Financial Query

```
POST /a2a/v1/process
```

Process a financial query from another agent.

**Request Body:**

```json
{
  "message_id": "a2a-123e4567-e89b-12d3-a456-426614174000",
  "sender": "agent-social",
  "query_type": "financial_analysis",
  "priority": "normal",
  "content": {
    "text": "Analyze expense categories for YouTube channel production costs",
    "context": {
      "business_type": "content_creation",
      "expense_categories": ["equipment", "software", "services"]
    },
    "parameters": {
      "detail_level": "high",
      "tax_implications": true
    }
  },
  "response_format": "json",
  "callback_url": "http://agent-social:9000/a2a/v1/callback",
  "metadata": {
    "session_id": "session-123",
    "user_id": "user-456"
  }
}
```

**Response:**

```json
{
  "message_id": "a2a-789a0123-b45c-67d8-e90f-123456789000",
  "in_reply_to": "a2a-123e4567-e89b-12d3-a456-426614174000",
  "status": "processing",
  "estimated_completion_time": "2025-05-12T14:30:00Z"
}
```

### A2A Callback Response

This is the format of the response that will be sent to the callback URL when processing is complete:

```json
{
  "message_id": "a2a-789a0123-b45c-67d8-e90f-123456789000",
  "in_reply_to": "a2a-123e4567-e89b-12d3-a456-426614174000",
  "status": "completed",
  "completion_time": "2025-05-12T14:29:45Z",
  "result": {
    "analysis": {
      "equipment": {
        "tax_treatment": "Depreciable asset for items over $2,500",
        "deduction_method": "Section 179 or depreciation",
        "typical_categories": ["cameras", "lighting", "audio", "computers"],
        "documentation_required": "Receipts, proof of business use percentage"
      },
      "software": {
        "tax_treatment": "Business expense",
        "deduction_method": "Direct expense",
        "typical_categories": ["editing", "graphics", "productivity", "analytics"],
        "documentation_required": "Subscription receipts or licenses"
      },
      "services": {
        "tax_treatment": "Business expense",
        "deduction_method": "Direct expense",
        "typical_categories": ["editing", "thumbnail design", "research", "consultants"],
        "documentation_required": "Invoices, contracts, 1099 reporting requirements"
      }
    },
    "recommendations": [
      "Track usage percentage for mixed-use equipment",
      "Consider setting up a dedicated business credit card for expenses",
      "Save receipts in digital format with proper categorization",
      "Review expenses quarterly for tax planning"
    ],
    "tax_implications": {
      "business_structure_impact": "Sole proprietor expenses reported on Schedule C",
      "estimated_tax_impact": "Regular quarterly estimated tax payments recommended",
      "home_office_considerations": "Dedicated space may qualify for home office deduction"
    }
  },
  "metadata": {
    "session_id": "session-123",
    "user_id": "user-456",
    "processing_time_ms": 12450
  }
}
```

## Error Responses

The API uses standard HTTP status codes and provides detailed error information:

```json
{
  "error": {
    "code": "validation_error",
    "message": "Invalid input parameters",
    "details": [
      {
        "field": "income.employment",
        "issue": "Value must be a positive number or zero"
      }
    ],
    "request_id": "req-123e4567-e89b-12d3-a456-426614174000"
  }
}
```

Common error codes:

- `validation_error`: Input validation failed
- `authentication_error`: Authentication failure
- `authorization_error`: Insufficient permissions
- `rate_limit_exceeded`: Too many requests
- `resource_not_found`: Requested resource does not exist
- `service_error`: Internal service error

## Webhooks

The Financial-Tax Agent can send webhook notifications for:

- Completed tax estimates
- Generated financial reports
- Compliance alerts
- Scheduled reports

### Webhook Configuration

To configure webhooks, use the following endpoint:

```
POST /webhooks/config
```

**Request Body:**

```json
{
  "url": "https://your-service.example.com/webhooks/financial",
  "secret": "your-webhook-secret",
  "events": ["tax.estimate.completed", "finance.report.completed"],
  "description": "Main application webhook for financial events"
}
```

**Response:**

```json
{
  "webhook_id": "webhook-123e4567-e89b-12d3-a456-426614174000",
  "status": "active",
  "created_at": "2025-05-12T14:35:22Z",
  "events": ["tax.estimate.completed", "finance.report.completed"]
}
```

### Webhook Payload Example

```json
{
  "event": "tax.estimate.completed",
  "webhook_id": "webhook-123e4567-e89b-12d3-a456-426614174000",
  "timestamp": "2025-05-12T15:01:35Z",
  "data": {
    "request_id": "tax-est-123e4567-e89b-12d3-a456-426614174000",
    "summary": {
      "total_tax": 12126.00,
      "effective_tax_rate": 12.01
    },
    "result_url": "https://agent-financial:9003/api/v1/tax/estimate/tax-est-123e4567-e89b-12d3-a456-426614174000"
  }
}
```

## SDK Libraries

SDKs are available for easy integration:

- **Python**: `pip install alfred-financial-client`
- **JavaScript**: `npm install alfred-financial-client`

## Usage Examples

### Python Example

```python
from alfred_financial_client import FinancialTaxClient

# Initialize client
client = FinancialTaxClient(
    api_key="your-api-key",
    base_url="http://agent-financial:9003/api/v1"
)

# Calculate tax estimate
estimate = client.calculate_tax_estimate(
    income={
        "employment": 85000.00,
        "self_employment": 12000.00,
        "investments": 3500.00
    },
    deductions={
        "retirement_contributions": 6000.00,
        "health_insurance": 3200.00
    },
    tax_year=2025,
    filing_status="married_joint",
    dependents=2,
    state="CA"
)

print(f"Total tax estimate: ${estimate.summary.total_tax:.2f}")
print(f"Effective tax rate: {estimate.summary.effective_tax_rate:.2f}%")

# Process recommendations
for rec in estimate.recommendations:
    print(f"Recommendation: {rec.description} (Impact: ${rec.impact:.2f})")
```

### JavaScript Example

```javascript
const { FinancialTaxClient } = require('alfred-financial-client');

// Initialize client
const client = new FinancialTaxClient({
  apiKey: 'your-api-key',
  baseUrl: 'http://agent-financial:9003/api/v1'
});

// Generate financial report
async function generateReport() {
  try {
    const report = await client.generateFinancialReport({
      transactions: [
        {
          date: '2025-04-15',
          amount: -1250.00,
          category: 'housing',
          description: 'Monthly rent payment'
        },
        // Additional transactions...
      ],
      report_type: 'monthly',
      time_period: {
        start_date: '2025-04-01',
        end_date: '2025-04-30'
      },
      include_forecasting: true
    });
    
    console.log('Report generated:', report.report_id);
    console.log(`Net cash flow: $${report.summary.net_cash_flow.toFixed(2)}`);
    console.log(`Savings rate: ${report.summary.savings_rate.toFixed(2)}%`);
    
    // Process recommendations
    report.recommendations.forEach(rec => {
      console.log(`${rec.priority.toUpperCase()} - ${rec.description}`);
    });
  } catch (error) {
    console.error('Error generating report:', error.message);
  }
}

generateReport();
```

## References

- [A2A Protocol Documentation](/docs/api/a2a-protocol.md)
- [Financial Data Models](/docs/agents/financial_tax/models.py)
- [Financial-Tax Agent Architecture](/docs/agents/financial_tax/financial-tax-agent-architecture.md)
- [Tax Compliance Standards](/docs/agents/financial_tax/tax-compliance-verification.md)
- [Agent Catalog](/docs/agents/catalog/agent-catalog.md)
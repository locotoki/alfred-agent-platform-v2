# Financial-Tax Agent Documentation

## Overview

The Financial-Tax Agent provides tax calculation, financial analysis, and compliance checking services within the Alfred Agent Platform. It leverages LangChain and LangGraph for intelligent processing of financial and tax-related tasks.

## Supported Intents

1. **TAX_CALCULATION** - Calculate tax liability based on income, deductions, and credits
2. **FINANCIAL_ANALYSIS** - Perform comprehensive financial analysis on statements
3. **TAX_COMPLIANCE_CHECK** - Check compliance with tax regulations
4. **RATE_SHEET_LOOKUP** - Look up tax rates for specific jurisdictions

## API Endpoints

### Tax Calculation
```
POST /api/v1/financial-tax/calculate-tax
```
Calculate tax liability for an individual or entity.

**Request Body:**
```json
{
  "income": 100000,
  "deductions": {
    "mortgage_interest": 12000,
    "charitable": 5000
  },
  "credits": {
    "child_tax_credit": 2000
  },
  "jurisdiction": "US-CA",
  "tax_year": 2024,
  "entity_type": "individual"
}
```

### Financial Analysis
```
POST /api/v1/financial-tax/analyze-financials
```
Analyze financial statements and provide insights.

**Request Body:**
```json
{
  "financial_statements": {
    "income_statement": {
      "revenue": 1000000,
      "expenses": 750000
    },
    "balance_sheet": {
      "assets": 2000000,
      "liabilities": 800000
    }
  },
  "analysis_type": "profitability",
  "period": "Q4 2024",
  "industry": "technology"
}
```

### Compliance Check
```
POST /api/v1/financial-tax/check-compliance
```
Check tax compliance for transactions.

**Request Body:**
```json
{
  "entity_type": "corporation",
  "transactions": [
    {
      "type": "sale",
      "amount": 50000,
      "date": "2024-01-15"
    }
  ],
  "jurisdiction": "US-NY",
  "tax_year": 2024,
  "compliance_areas": ["sales_tax", "income_tax"]
}
```

### Tax Rate Lookup
```
GET /api/v1/financial-tax/tax-rates/{jurisdiction}
```
Retrieve tax rates for a specific jurisdiction.

**Parameters:**
- `jurisdiction` (required): Tax jurisdiction code
- `tax_year` (optional): Tax year (default: current year)
- `entity_type` (optional): Entity type (default: individual)

## Configuration

### Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `DATABASE_URL` | PostgreSQL connection string | Yes | - |
| `REDIS_URL` | Redis connection string | Yes | redis://redis:6379 |
| `PUBSUB_EMULATOR_HOST` | Pub/Sub emulator host | Yes | pubsub-emulator:8085 |
| `OPENAI_API_KEY` | OpenAI API key | Yes | - |
| `LANGSMITH_API_KEY` | LangSmith API key | No | - |
| `LANGCHAIN_TRACING_V2` | Enable LangChain tracing | No | false |

## Integration Guide

### With Other Agents

The Financial-Tax Agent can be integrated with other agents in the platform:

1. **Legal Compliance Agent Integration**
   ```json
   {
     "intent": "TRIGGER_TAX_CALCULATION",
     "source": "legal-compliance-agent",
     "data": {
       "entity_id": "12345",
       "reason": "quarterly_compliance_check"
     }
   }
   ```

2. **Alfred Bot Integration**
   ```
   /alfred tax-calculate income=100000 jurisdiction=US-CA
   ```

### Event Flow

1. Request received via API or agent trigger
2. Task created and stored in Supabase
3. Message published to Pub/Sub
4. Financial-Tax Agent processes task
5. Results stored in database
6. Completion event published
7. Response returned to caller

## Monitoring

### Metrics

The agent exposes the following Prometheus metrics:

- `financial_tax_tasks_total`: Total tasks processed
- `financial_tax_task_duration_seconds`: Task processing duration
- `financial_tax_api_requests_total`: API request count
- `financial_tax_active_tasks`: Currently processing tasks

### Health Checks

```
GET /health/health      # Basic health check
GET /health/ready       # Readiness check
GET /health/live        # Liveness check
GET /health/metrics     # Prometheus metrics
```

## Error Handling

### Common Error Codes

| Code | Description | Resolution |
|------|-------------|------------|
| 400 | Invalid request data | Check request format |
| 401 | Unauthorized | Provide valid authentication |
| 404 | Resource not found | Verify endpoint/ID |
| 429 | Rate limit exceeded | Wait before retrying |
| 500 | Internal server error | Contact support |

### Retry Policy

Failed tasks are automatically retried with exponential backoff:
- Max retries: 3
- Initial delay: 1 second
- Max delay: 30 seconds
- Backoff multiplier: 2

## Troubleshooting

### Common Issues

1. **Task Stuck in Processing**
   - Check agent logs: `docker logs financial-tax`
   - Verify Pub/Sub connectivity
   - Check database connection

2. **High Error Rate**
   - Monitor error logs
   - Check OpenAI API quota
   - Verify input validation

3. **Slow Response Times**
   - Check system resources
   - Monitor task queue length
   - Scale up if needed

### Debug Commands

```bash
# View agent logs
docker logs -f financial-tax

# Check agent status
curl http://localhost:9003/health/health

# Monitor metrics
curl http://localhost:9003/health/metrics

# Check database connection
docker exec financial-tax python -m libs.check_db
```

## Development

### Local Setup

1. Clone repository
2. Install dependencies:
   ```bash
   pip install -r services/financial-tax/requirements.txt
   ```
3. Start services:
   ```bash
   docker-compose up -d
   ```
4. Run agent:
   ```bash
   cd services/financial-tax
   uvicorn app.main:app --reload
   ```

### Testing

```bash
# Run unit tests
pytest agents/financial_tax/tests/

# Run integration tests
pytest tests/integration/financial_tax/

# Run with coverage
pytest --cov=agents/financial_tax
```

### Adding New Features

1. Add new intent to `supported_intents`
2. Create new chain in `chains.py`
3. Add handler method to agent
4. Update workflow graph
5. Add tests
6. Update documentation

## Security

### Authentication

All API endpoints require Bearer token authentication:

```
Authorization: Bearer <token>
```

### Data Protection

- PII automatically scrubbed from logs
- Sensitive data encrypted at rest
- TLS encryption for all communications
- Rate limiting per user/IP

### Compliance

- GDPR compliant data handling
- SOC 2 Type II certified infrastructure
- Regular security audits
- Automated vulnerability scanning

## API Reference

For detailed API documentation, see [Financial-Tax API Specification](../api/financial-tax-api.yaml)

## Support

For issues and feature requests, please contact:
- Email: support@alfred-platform.com
- Slack: #financial-tax-support
- GitHub: [alfred-platform/agents](https://github.com/alfred-platform/agents/issues)

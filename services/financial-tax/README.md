# Financial-Tax Agent Service

This service provides tax calculation, financial analysis, and regulatory compliance capabilities through an LLM-powered agent.

## Platform Integration

The Financial-Tax agent has been integrated with the Alfred Agent Platform services, including:

1. **RAG Gateway Integration**: Provides context-aware retrieval for tax regulations, financial analysis, and compliance checking
2. **Supabase Persistence**: Multi-tenant storage with proper RLS policies
3. **Authentication**: Standardized API key and JWT validation

## Migration Modes

The service can operate in three migration modes:

- **legacy**: Uses original implementation only
- **hybrid**: Uses platform services with fallback to original implementation
- **platform**: Uses platform services exclusively

The migration mode is controlled via the `MIGRATION_MODE` environment variable in `.env.migration`.

## Setup

### Prerequisites

- Docker and Docker Compose
- Access to the Supabase instance
- Access to the RAG Gateway service

### Initial Setup

1. Create required tables in Supabase:
   ```
   ./setup_financial_tables.sh
   ```

2. Configure environment variables:
   ```
   cp .env.migration .env
   ```

3. Modify `.env` with your specific configuration as needed

### Running the Service

```
docker-compose up financial-tax
```

## API Endpoints

- `POST /api/v1/financial-tax/calculate-tax`: Calculate tax liability
- `POST /api/v1/financial-tax/analyze-financials`: Perform financial analysis
- `POST /api/v1/financial-tax/check-compliance`: Check tax compliance
- `GET /api/v1/financial-tax/tax-rates/{jurisdiction}`: Retrieve tax rates
- `GET /api/v1/financial-tax/task/{task_id}`: Get task status

## Authentication

The service supports multiple authentication methods:
- API Key via `X-API-Key` header
- JWT via `Authorization: Bearer` header
- Legacy Bearer token via `Authorization: Bearer` header

## Knowledge Integration

Each endpoint retrieves specialized knowledge from the RAG Gateway:
- Tax calculations use jurisdiction and entity-specific tax knowledge
- Financial analysis incorporates industry and statement-type knowledge
- Compliance checks integrate regulatory requirements
- Tax rate lookups include up-to-date rate sheets
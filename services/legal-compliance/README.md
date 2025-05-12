# Legal-Compliance Agent Service

This service provides legal compliance capabilities including compliance audits, document analysis, regulation checks, and contract reviews through an LLM-powered agent.

## Platform Integration

The Legal-Compliance agent has been integrated with the Alfred Agent Platform services, including:

1. **RAG Gateway Integration**: Context-aware retrieval for legal knowledge, regulations, and contract templates
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
   ./setup_legal_tables.sh
   ```

2. Configure environment variables:
   ```
   cp .env.migration .env
   ```

3. Modify `.env` with your specific configuration as needed

### Running the Service

```
docker-compose up legal-compliance
```

## API Endpoints

- `POST /api/v1/legal-compliance/audit-compliance`: Perform compliance audit on submitted documents and processes
- `POST /api/v1/legal-compliance/analyze-document`: Analyze legal document for compliance issues
- `POST /api/v1/legal-compliance/check-regulations`: Check compliance against specific regulations
- `POST /api/v1/legal-compliance/review-contract`: Review contract for legal compliance and potential issues
- `GET /api/v1/legal-compliance/task/{task_id}`: Get task status

## Authentication

The service supports multiple authentication methods:
- API Key via `X-API-Key` header
- JWT via `Authorization: Bearer` header
- Legacy Bearer token via `Authorization: Bearer` header

## Knowledge Integration

Each endpoint retrieves specialized knowledge from the RAG Gateway:
- Compliance audits use category-specific compliance requirements
- Document analysis incorporates document type and jurisdictional context
- Regulation checks include specific regulation details by jurisdiction
- Contract reviews integrate contract templates and legal precedents

## Testing

### Setup

Install the test dependencies:
```
pip install -r requirements-test.txt
```

### Running Tests

The service has three levels of tests:

1. **Unit Tests**: Test individual components in isolation
   ```
   make test-unit
   ```

2. **Integration Tests**: Test API endpoints with mocked dependencies
   ```
   make test-integration
   ```

3. **End-to-End Tests**: Test complete workflows with live services
   ```
   make test-e2e
   ```

Run all tests with coverage report:
```
make test
```

### Configuring End-to-End Tests

E2E tests require a running environment. Set the following environment variables:

```
export API_BASE_URL=http://localhost:8000
export TEST_API_KEY=legal-compliance-key
export JWT_SECRET=your-secret-key
export RUN_E2E_TESTS=true
```
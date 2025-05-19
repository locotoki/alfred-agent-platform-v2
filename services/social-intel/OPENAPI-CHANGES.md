# OpenAPI and Swagger UI Integration

## Overview

This patch adds OpenAPI 3.0 documentation and Swagger UI to the Social Intelligence service. The implementation provides:

1. A comprehensive OpenAPI 3.0 specification in YAML format
2. Swagger UI hosted at `/docs` for interactive API exploration
3. Validation tooling via Redocly CLI

## Files Added

- `api/openapi.yaml`: The OpenAPI 3.0 specification
- `scripts/validate_openapi.sh`: Script to validate the OpenAPI schema

## Files Modified

- `app/main.py`: Added routes for serving the OpenAPI spec and Swagger UI
- `requirements.txt`: Added PyYAML dependency
- `package.json`: Added validation script and Redocly dependency
- `README.md`: Updated with API documentation information
- `Dockerfile`: Ensure API directory exists in the container

## Features

The OpenAPI specification includes:

- Detailed endpoint documentation for all API routes
- Request/response schemas with examples
- Parameter descriptions and validation rules
- Tags for logical grouping of endpoints
- Server configurations for different environments

The Swagger UI provides:

- Interactive API documentation
- Try-it-out functionality for testing endpoints
- Request/response examples
- Schema validation

## Usage

### View API Documentation

Navigate to:
```
http://localhost:9000/docs
```

### Validate OpenAPI Specification

```bash
npm run test:api
```

## Implementation Details

Instead of using FastAPI's built-in OpenAPI generator, we've opted for a custom approach with several benefits:

1. **Customization**: Complete control over the OpenAPI spec format and content
2. **Precision**: Hand-crafted schemas that exactly match our API's behavior
3. **Maintainability**: Separating the specification from the code
4. **Validation**: Ability to validate against standards using specialized tools

The implementation uses:
- FastAPI's routing to serve the custom OpenAPI YAML file
- A custom HTML template for Swagger UI that loads our spec
- A custom override of FastAPI's built-in OpenAPI schema generator

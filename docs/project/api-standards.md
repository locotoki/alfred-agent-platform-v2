# API Standards

**Last Updated:** 2025-05-12  
**Owner:** API Team  
**Status:** Active

## Overview

This document defines the API standards for the Alfred Agent Platform v2. It establishes consistent guidelines for designing, implementing, and maintaining APIs across all platform components. These standards ensure interoperability, maintainability, and a consistent developer experience when working with platform APIs. They apply to RESTful HTTP APIs, internal service-to-service communications, and agent-to-agent protocols within the platform.

## Project Metadata

| Attribute | Value |
|-----------|-------|
| Status | Active |
| Start Date | 2025-01-15 |
| Last Updated | 2025-05-12 |
| Current Phase | Phase 6: Financial-Tax Agent |
| Repository | [AI Agent Platform v2](https://github.com/alfred-agent-platform/v2) |

## API Design Principles

### Core Principles

1. **Consistency**: APIs should be consistent in naming, structure, and behavior across the platform
2. **Simplicity**: APIs should be intuitive and easy to understand
3. **Evolvability**: APIs should be designed to evolve over time without breaking existing clients
4. **Security**: Security should be built into APIs from the start
5. **Documentation**: All APIs should be thoroughly documented

### REST API Design

1. **Resource-Oriented Design**: APIs should be organized around resources
2. **Standard HTTP Methods**: Use standard HTTP methods (GET, POST, PUT, DELETE)
3. **Consistent URL Patterns**: Follow consistent URL patterns for resource paths
4. **Appropriate Status Codes**: Use appropriate HTTP status codes
5. **Pagination, Filtering, and Sorting**: Support for data retrieval operations
6. **Versioning**: API versioning strategy to manage changes

### A2A Protocol Standards

1. **Envelope-Based Messaging**: Use standardized message envelope format
2. **Intent-Driven Design**: Organize operations around clear intents
3. **Asynchronous Operations**: Support for asynchronous processing
4. **Exactly-Once Processing**: Guarantee exactly-once processing semantics
5. **Secure Communication**: Ensure secure communication between agents

## REST API Standards

### URL Structure

All API URLs should follow this structure:

```
https://{service-name}.alfred.io/api/v{major-version}/{resource}[/{resource-id}][/{sub-resource}]
```

Examples:
- `https://social-intel.alfred.io/api/v1/niche-scout`
- `https://financial-tax.alfred.io/api/v1/tax-compliance/checks/123`

### HTTP Methods

| Method | Purpose | Idempotent | Safe |
|--------|---------|------------|------|
| GET | Retrieve a resource or collection | Yes | Yes |
| POST | Create a new resource | No | No |
| PUT | Update a resource (full replacement) | Yes | No |
| PATCH | Update a resource (partial update) | No | No |
| DELETE | Delete a resource | Yes | No |

### Status Codes

| Category | Codes | Purpose |
|----------|-------|---------|
| Success | 200 OK | Standard success response |
| | 201 Created | Resource creation success |
| | 204 No Content | Success with no response body |
| Redirection | 301 Moved Permanently | Resource URL has changed permanently |
| | 304 Not Modified | Response hasn't changed since last request |
| Client Error | 400 Bad Request | Malformed request |
| | 401 Unauthorized | Authentication failure |
| | 403 Forbidden | Authorization failure |
| | 404 Not Found | Resource not found |
| | 409 Conflict | Request conflicts with current state |
| | 422 Unprocessable Entity | Validation errors |
| | 429 Too Many Requests | Rate limit exceeded |
| Server Error | 500 Internal Server Error | Server-side error |
| | 503 Service Unavailable | Service temporarily unavailable |

### Query Parameters

| Parameter | Purpose | Example |
|-----------|---------|---------|
| `filter` | Filter results | `?filter=status:active` |
| `sort` | Sort results | `?sort=created_at:desc` |
| `page` | Pagination page number | `?page=2` |
| `limit` | Pagination page size | `?limit=25` |
| `fields` | Field selection | `?fields=id,name,created_at` |
| `expand` | Expand related resources | `?expand=user,comments` |

### Request/Response Format

#### Request Format

```json
{
  "property1": "value1",
  "property2": 123,
  "nested_object": {
    "nested_property": "value"
  },
  "array_property": [1, 2, 3]
}
```

#### Success Response Format

```json
{
  "data": {
    "id": "resource-id",
    "type": "resource-type",
    "attributes": {
      "property1": "value1",
      "property2": 123
    },
    "relationships": {
      "related_resource": {
        "id": "related-id",
        "type": "related-type"
      }
    }
  },
  "meta": {
    "request_id": "req-abc-123",
    "timestamp": "2025-05-12T14:30:45Z"
  }
}
```

#### Collection Response Format

```json
{
  "data": [
    {
      "id": "resource-id-1",
      "type": "resource-type",
      "attributes": {
        "property1": "value1"
      }
    },
    {
      "id": "resource-id-2",
      "type": "resource-type",
      "attributes": {
        "property1": "value2"
      }
    }
  ],
  "pagination": {
    "total_count": 50,
    "page": 1,
    "limit": 25,
    "next_page": "/api/v1/resources?page=2&limit=25",
    "prev_page": null
  },
  "meta": {
    "request_id": "req-abc-123",
    "timestamp": "2025-05-12T14:30:45Z"
  }
}
```

#### Error Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input parameters",
    "details": [
      {
        "field": "email",
        "code": "INVALID_FORMAT",
        "message": "Email address format is invalid"
      }
    ]
  },
  "meta": {
    "request_id": "req-abc-123",
    "timestamp": "2025-05-12T14:30:45Z"
  }
}
```

### Versioning

API versioning is managed through:

1. **URL Path Versioning**: Major version in the URL path (`/api/v1/`, `/api/v2/`)
2. **Header Versioning** (for minor versions): `X-API-Version: 1.2`

Versioning rules:
- Breaking changes require a major version increment
- Non-breaking additions require a minor version increment
- Bug fixes and documentation updates require a patch version increment

### Authentication

APIs should support these authentication methods:

1. **API Key Authentication**:
   - Header: `X-API-Key: {api-key}`
   - Used for service-to-service communications

2. **JWT Authentication**:
   - Header: `Authorization: Bearer {jwt-token}`
   - Used for authenticated user requests

3. **OAuth 2.0**:
   - For third-party integrations
   - Supports authorization code and client credentials flows

### Rate Limiting

Rate limiting uses the following headers:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1620000000
```

When rate limits are exceeded, return:
- Status code: `429 Too Many Requests`
- Response header: `Retry-After: 30` (seconds until retry is allowed)

## A2A Protocol Standards

The A2A (Agent-to-Agent) Protocol defines how agents communicate within the platform.

### Message Envelope

All A2A messages use this envelope structure:

```json
{
  "envelope": {
    "metadata": {
      "id": "string",
      "version": "string",
      "timestamp": "ISO8601 datetime",
      "correlation_id": "string",
      "trace_id": "string"
    },
    "routing": {
      "source": {
        "agent_id": "string",
        "service_id": "string"
      },
      "destination": {
        "agent_id": "string",
        "service_id": "string"
      },
      "reply_to": "string"
    },
    "security": {
      "auth_token": "string",
      "signature": "string",
      "tenant_id": "string"
    }
  },
  "message": {
    "type": "string",
    "intent": "string",
    "payload": {}
  }
}
```

### Message Types

The A2A protocol supports these message types:

| Type | Description | Transport Topic |
|------|-------------|----------------|
| TASK_REQUEST | Request for an agent to perform a task | a2a.tasks.create |
| TASK_RESPONSE | Response with task results | a2a.tasks.completed |
| EVENT | Notification of an occurrence | a2a.events |
| HEARTBEAT | Agent availability signal | a2a.heartbeats |
| DISCOVERY | Service discovery message | a2a.discovery |
| CONTROL | System control message | a2a.control |

### Transport Mechanisms

A2A Protocol supports two transport mechanisms:

1. **Primary: Google Cloud Pub/Sub**
   - At-least-once delivery
   - Ordered message delivery
   - Dead-letter queue support

2. **Secondary: Supabase Realtime**
   - WebSocket-based real-time communications
   - Database-backed persistence

For detailed A2A Protocol specifications, see the [A2A Protocol Documentation](../api/a2a-protocol.md).

## Service API Implementation

### Service API Endpoints

Each service should implement these standard endpoints:

1. **Health Check Endpoint**
   ```
   GET /health
   ```
   Response:
   ```json
   {
     "status": "healthy",
     "version": "1.2.3",
     "timestamp": "2025-05-12T14:30:45Z",
     "checks": {
       "database": "connected",
       "dependencies": "healthy"
     }
   }
   ```

2. **Status Endpoint**
   ```
   GET /status
   ```
   Response:
   ```json
   {
     "agent": "service-name",
     "version": "1.2.3",
     "status": "running",
     "supported_intents": ["INTENT_1", "INTENT_2"],
     "uptime": 3600,
     "last_restart": "2025-05-12T12:30:45Z"
   }
   ```

3. **OpenAPI Documentation Endpoint**
   ```
   GET /api/docs
   ```
   Serves Swagger UI with OpenAPI documentation

### Logging and Monitoring

APIs should include these observability elements:

1. **Request Tracing**
   - Generate a request ID for each request
   - Include in response headers: `X-Request-ID: req-abc-123`
   - Log all request/response pairs with the request ID

2. **Performance Metrics**
   - Track response times
   - Monitor error rates
   - Export metrics via Prometheus format

3. **Structured Logging**
   - Use structured log format
   - Include context attributes (request ID, user ID, etc.)
   - Follow log level guidelines

## API Documentation

### Documentation Requirements

All APIs must include:

1. **OpenAPI 3.0+ Specification**
   - Complete schema definitions
   - Request/response examples
   - Error responses
   - Authentication requirements

2. **Developer Documentation**
   - Getting started guides
   - Authentication guidance
   - Example request/response pairs
   - Implementation notes

3. **Changelog**
   - Version history
   - Breaking vs. non-breaking changes
   - Migration guidance for API consumers

### Documentation Format

```yaml
openapi: 3.0.3
info:
  title: Service Name API
  description: |
    Detailed description of the service and its capabilities
    
    ## Features
    
    - Feature 1
    - Feature 2
  version: 1.0.0
  contact:
    name: Alfred Agent Platform Team
    url: https://github.com/your-org/alfred-agent-platform
  license:
    name: Proprietary
servers:
  - url: https://service-name.alfred.io
    description: Production server
tags:
  - name: resource-name
    description: Resource description
paths:
  /api/v1/resource:
    get:
      summary: List resources
      description: Detailed description of the operation
      operationId: listResources
      parameters:
        - name: limit
          in: query
          description: Maximum number of resources to return
          schema:
            type: integer
            default: 25
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ResourceList'
components:
  schemas:
    Resource:
      type: object
      properties:
        id:
          type: string
          description: Resource ID
          example: "res-123"
```

## API Security

### Security Requirements

All APIs must implement:

1. **Authentication**
   - Every request must be authenticated
   - Use appropriate auth method for the context

2. **Authorization**
   - Role-based access control
   - Resource ownership verification
   - Fine-grained permission checks

3. **Input Validation**
   - Validate all input parameters
   - Enforce schema validation
   - Sanitize inputs to prevent injection attacks

4. **Rate Limiting**
   - Protect against abuse and DoS
   - Implement tiered rate limits
   - Provide clear rate limit information

5. **Transport Security**
   - TLS 1.3+ for all communications
   - Strong cipher suites
   - Certificate validation

### Security Headers

All API responses should include:

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'none'
Cache-Control: no-store
```

## Implementation Examples

### Python FastAPI Example

```python
from fastapi import FastAPI, Depends, HTTPException, Header
from pydantic import BaseModel
from typing import List, Optional
import uuid

app = FastAPI(
    title="Resource Service API",
    description="Service for managing resources",
    version="1.0.0"
)

class ResourceCreate(BaseModel):
    name: str
    description: Optional[str] = None
    
class Resource(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    created_at: str

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": "2025-05-12T14:30:45Z"
    }

@app.get("/api/v1/resources", response_model=List[Resource])
async def list_resources(
    limit: int = 25,
    page: int = 1,
    x_api_key: str = Header(None)
):
    # Validate API key
    if not is_valid_api_key(x_api_key):
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    # Get resources from database
    resources = get_resources(limit, page)
    
    # Return formatted response
    return resources

@app.post("/api/v1/resources", response_model=Resource, status_code=201)
async def create_resource(
    resource: ResourceCreate,
    x_api_key: str = Header(None)
):
    # Validate API key
    if not is_valid_api_key(x_api_key):
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    # Create resource in database
    resource_id = str(uuid.uuid4())
    new_resource = create_resource_in_db(resource_id, resource)
    
    # Return created resource
    return new_resource
```

### Node.js Express Example

```typescript
import express from 'express';
import { v4 as uuidv4 } from 'uuid';
import { z } from 'zod';

const app = express();
app.use(express.json());

// Schema validation
const ResourceCreateSchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string().optional()
});

// API key middleware
const validateApiKey = (req, res, next) => {
  const apiKey = req.header('X-API-Key');
  
  if (!isValidApiKey(apiKey)) {
    return res.status(401).json({
      error: {
        code: 'UNAUTHORIZED',
        message: 'Invalid API key'
      }
    });
  }
  
  next();
};

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// List resources endpoint
app.get('/api/v1/resources', validateApiKey, (req, res) => {
  const limit = parseInt(req.query.limit) || 25;
  const page = parseInt(req.query.page) || 1;
  
  // Get resources from database
  const resources = getResourcesFromDb(limit, page);
  const totalCount = getTotalResourceCount();
  
  // Return formatted response
  res.json({
    data: resources.map(resource => ({
      id: resource.id,
      type: 'resource',
      attributes: {
        name: resource.name,
        description: resource.description,
        created_at: resource.created_at
      }
    })),
    pagination: {
      total_count: totalCount,
      page: page,
      limit: limit,
      next_page: page * limit < totalCount ? `/api/v1/resources?page=${page + 1}&limit=${limit}` : null,
      prev_page: page > 1 ? `/api/v1/resources?page=${page - 1}&limit=${limit}` : null
    },
    meta: {
      request_id: req.headers['x-request-id'] || uuidv4(),
      timestamp: new Date().toISOString()
    }
  });
});

// Create resource endpoint
app.post('/api/v1/resources', validateApiKey, (req, res) => {
  try {
    // Validate request body
    const validatedData = ResourceCreateSchema.parse(req.body);
    
    // Create resource in database
    const resourceId = uuidv4();
    const newResource = createResourceInDb(resourceId, validatedData);
    
    // Return formatted response
    res.status(201).json({
      data: {
        id: newResource.id,
        type: 'resource',
        attributes: {
          name: newResource.name,
          description: newResource.description,
          created_at: newResource.created_at
        }
      },
      meta: {
        request_id: req.headers['x-request-id'] || uuidv4(),
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(422).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid input parameters',
          details: error.errors.map(err => ({
            field: err.path.join('.'),
            code: 'INVALID_FORMAT',
            message: err.message
          }))
        },
        meta: {
          request_id: req.headers['x-request-id'] || uuidv4(),
          timestamp: new Date().toISOString()
        }
      });
    }
    
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Internal server error'
      },
      meta: {
        request_id: req.headers['x-request-id'] || uuidv4(),
        timestamp: new Date().toISOString()
      }
    });
  }
});

app.listen(3000, () => {
  console.log('API server listening on port 3000');
});
```

## Testing Standards

### API Testing Requirements

All APIs must include:

1. **Unit Tests**
   - Test request validation
   - Test business logic
   - Test error handling

2. **Integration Tests**
   - Test end-to-end request handling
   - Test database interactions
   - Test authentication and authorization

3. **Contract Tests**
   - Validate API conforms to its specification
   - Test against OpenAPI schema

4. **Performance Tests**
   - Load testing
   - Stress testing
   - Latency testing

### Example Test Cases

```python
# Unit test example
def test_validate_resource_create():
    # Test valid input
    valid_input = {"name": "Test Resource", "description": "Test Description"}
    validated = ResourceCreate.model_validate(valid_input)
    assert validated.name == "Test Resource"
    assert validated.description == "Test Description"
    
    # Test invalid input
    invalid_input = {"description": "Missing name field"}
    with pytest.raises(ValidationError):
        ResourceCreate.model_validate(invalid_input)

# Integration test example
async def test_create_resource_endpoint():
    response = await client.post(
        "/api/v1/resources",
        headers={"X-API-Key": "test-api-key"},
        json={"name": "Test Resource", "description": "Test Description"}
    )
    
    assert response.status_code == 201
    data = response.json()["data"]
    assert data["attributes"]["name"] == "Test Resource"
    assert data["attributes"]["description"] == "Test Description"
    assert "id" in data
    
    # Verify resource was created in database
    resource = await get_resource_from_db(data["id"])
    assert resource is not None
    assert resource.name == "Test Resource"
```

## Conclusion

These API standards provide a comprehensive framework for designing, implementing, and maintaining APIs across the Alfred Agent Platform v2. By following these standards, we ensure that all platform components work together seamlessly, providing a consistent and reliable experience for developers and users.

For implementation guidance, refer to the language-specific examples provided in this document. For additional details on the A2A Protocol, refer to the [A2A Protocol Documentation](../api/a2a-protocol.md).

## References

- [REST API Design Best Practices](https://www.ics.uci.edu/~fielding/pubs/dissertation/rest_arch_style.htm)
- [OpenAPI Specification](https://swagger.io/specification/)
- [JSON:API Specification](https://jsonapi.org/)
- [OAuth 2.0 Specification](https://oauth.net/2/)
- [Google API Design Guide](https://cloud.google.com/apis/design)
- [Microsoft REST API Guidelines](https://github.com/microsoft/api-guidelines/blob/vNext/Guidelines.md)
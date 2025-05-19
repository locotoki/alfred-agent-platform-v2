# API Schema: A2A Message Envelope

*Last Updated: 2025-05-13*
*Owner: API Team*
*Status: Active*

## Overview

The Agent-to-Agent (A2A) Message Envelope schema defines the standardized structure for all communication between agents in the Alfred Agent Platform. This envelope-based approach ensures consistent message handling, reliable routing, proper security validation, and effective tracing across the distributed system. The envelope wraps the actual message content, providing necessary metadata without affecting the payload semantics.

This schema is critical for maintaining interoperability between agents regardless of their implementation details, ensuring that all platform components can effectively communicate while maintaining system integrity.

## Schema Definition

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "A2A Message Envelope",
  "description": "JSON Schema for Agent-to-Agent (A2A) message envelope format",
  "type": "object",
  "required": ["envelope", "message"],
  "properties": {
    "envelope": {
      "type": "object",
      "required": ["metadata", "routing", "security"],
      "properties": {
        "metadata": {
          "type": "object",
          "required": ["id", "version", "timestamp"],
          "properties": {
            "id": {
              "type": "string",
              "format": "uuid",
              "description": "Unique message identifier"
            },
            "version": {
              "type": "string",
              "pattern": "^\\d+\\.\\d+\\.\\d+$",
              "description": "Protocol version (semantic versioning)"
            },
            "timestamp": {
              "type": "string",
              "format": "date-time",
              "description": "Message creation timestamp"
            },
            "correlation_id": {
              "type": "string",
              "format": "uuid",
              "description": "Optional ID linking related messages"
            },
            "trace_id": {
              "type": "string",
              "description": "Distributed tracing ID"
            }
          }
        },
        "routing": {
          "type": "object",
          "required": ["source", "destination"],
          "properties": {
            "source": {
              "type": "object",
              "required": ["agent_id", "service_id"],
              "properties": {
                "agent_id": {
                  "type": "string",
                  "maxLength": 64,
                  "description": "Originating agent identifier"
                },
                "service_id": {
                  "type": "string",
                  "maxLength": 64,
                  "description": "Originating service identifier"
                }
              }
            },
            "destination": {
              "type": "object",
              "required": ["agent_id"],
              "properties": {
                "agent_id": {
                  "type": "string",
                  "maxLength": 64,
                  "description": "Target agent identifier"
                },
                "service_id": {
                  "type": "string",
                  "maxLength": 64,
                  "description": "Optional target service identifier"
                }
              }
            },
            "reply_to": {
              "type": "string",
              "description": "Topic or channel for responses"
            }
          }
        },
        "security": {
          "type": "object",
          "required": ["auth_token"],
          "properties": {
            "auth_token": {
              "type": "string",
              "description": "Authentication token (JWT)"
            },
            "signature": {
              "type": "string",
              "description": "Optional message signature"
            },
            "tenant_id": {
              "type": "string",
              "maxLength": 64,
              "description": "Optional multi-tenant identifier"
            }
          }
        }
      }
    },
    "message": {
      "type": "object",
      "required": ["type", "intent"],
      "properties": {
        "type": {
          "type": "string",
          "enum": ["TASK_REQUEST", "TASK_RESPONSE", "EVENT", "HEARTBEAT", "DISCOVERY", "CONTROL"],
          "description": "Message classification"
        },
        "intent": {
          "type": "string",
          "description": "Specific operation being requested"
        },
        "payload": {
          "type": "object",
          "description": "Message content specific to the intent"
        }
      }
    }
  }
}
```

## Field Descriptions

### Top-Level Structure

| Field | Type | Required | Description | Constraints |
|-------|------|----------|-------------|------------|
| envelope | object | Yes | Contains routing, metadata, and security information | Must include metadata, routing, and security objects |
| message | object | Yes | Contains the message type, intent, and payload | Must include type and intent fields |

### Metadata Fields

| Field | Type | Required | Description | Constraints |
|-------|------|----------|-------------|------------|
| metadata.id | string | Yes | Unique identifier for the message | Must be a valid UUID v4 |
| metadata.version | string | Yes | Protocol version using semantic versioning | Must match pattern "x.y.z" |
| metadata.timestamp | string | Yes | When the message was created | ISO8601 formatted date-time |
| metadata.correlation_id | string | No | ID linking related messages in a sequence | Must be a valid UUID v4 when provided |
| metadata.trace_id | string | No | ID for distributed tracing across services | Follows tracing system format |

### Routing Fields

| Field | Type | Required | Description | Constraints |
|-------|------|----------|-------------|------------|
| routing.source.agent_id | string | Yes | ID of the agent sending the message | Max 64 characters |
| routing.source.service_id | string | Yes | ID of the service sending the message | Max 64 characters |
| routing.destination.agent_id | string | Yes | ID of the agent receiving the message | Max 64 characters |
| routing.destination.service_id | string | No | Optional ID of specific service receiving the message | Max 64 characters |
| routing.reply_to | string | No | Topic or channel where responses should be sent | Valid Pub/Sub topic or Supabase channel |

### Security Fields

| Field | Type | Required | Description | Constraints |
|-------|------|----------|-------------|------------|
| security.auth_token | string | Yes | JWT authentication token | Valid JWT with appropriate claims |
| security.signature | string | No | Digital signature for message verification | Typically HMAC-SHA256 encoded as Base64 |
| security.tenant_id | string | No | Identifier for multi-tenant deployments | Max 64 characters |

### Message Fields

| Field | Type | Required | Description | Constraints |
|-------|------|----------|-------------|------------|
| message.type | string | Yes | Classification of the message | Must be one of the predefined enum values |
| message.intent | string | Yes | Specific operation being requested | Should match registered agent capabilities |
| message.payload | object | No | Content specific to the intent | Structure varies by intent |

## Examples

### Basic Task Request Example

```json
{
  "envelope": {
    "metadata": {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "version": "2.1.0",
      "timestamp": "2025-05-13T14:30:00.000Z",
      "correlation_id": "123e4567-e89b-12d3-a456-426614174001",
      "trace_id": "abc123def456ghi789"
    },
    "routing": {
      "source": {
        "agent_id": "alfred-bot",
        "service_id": "alfred-bot-service"
      },
      "destination": {
        "agent_id": "social-intelligence-agent",
        "service_id": "social-intelligence-service"
      },
      "reply_to": "a2a.tasks.completed.alfred-bot"
    },
    "security": {
      "auth_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "tenant_id": "default"
    }
  },
  "message": {
    "type": "TASK_REQUEST",
    "intent": "TREND_ANALYSIS",
    "payload": {
      "query": "artificial intelligence advancements",
      "time_range": "last_30_days",
      "sources": ["twitter", "news", "blogs"]
    }
  }
}
```

### Task Response Example

```json
{
  "envelope": {
    "metadata": {
      "id": "123e4567-e89b-12d3-a456-426614174002",
      "version": "2.1.0",
      "timestamp": "2025-05-13T14:31:15.000Z",
      "correlation_id": "123e4567-e89b-12d3-a456-426614174001",
      "trace_id": "abc123def456ghi789"
    },
    "routing": {
      "source": {
        "agent_id": "social-intelligence-agent",
        "service_id": "social-intelligence-service"
      },
      "destination": {
        "agent_id": "alfred-bot",
        "service_id": "alfred-bot-service"
      }
    },
    "security": {
      "auth_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "tenant_id": "default"
    }
  },
  "message": {
    "type": "TASK_RESPONSE",
    "intent": "TREND_ANALYSIS",
    "payload": {
      "status": "SUCCESS",
      "results": {
        "trends": [
          {"topic": "generative AI", "mentions": 25600, "sentiment": 0.72},
          {"topic": "AI regulation", "mentions": 18400, "sentiment": 0.45},
          {"topic": "multimodal models", "mentions": 12300, "sentiment": 0.81}
        ],
        "summary": "Generative AI continues to dominate discussions...",
        "related_topics": ["machine learning", "neural networks", "transformers"]
      }
    }
  }
}
```

### Error Response Example

```json
{
  "envelope": {
    "metadata": {
      "id": "123e4567-e89b-12d3-a456-426614174003",
      "version": "2.1.0",
      "timestamp": "2025-05-13T14:31:05.000Z",
      "correlation_id": "123e4567-e89b-12d3-a456-426614174001",
      "trace_id": "abc123def456ghi789"
    },
    "routing": {
      "source": {
        "agent_id": "social-intelligence-agent",
        "service_id": "social-intelligence-service"
      },
      "destination": {
        "agent_id": "alfred-bot",
        "service_id": "alfred-bot-service"
      }
    },
    "security": {
      "auth_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "tenant_id": "default"
    }
  },
  "message": {
    "type": "TASK_RESPONSE",
    "intent": "TREND_ANALYSIS",
    "payload": {
      "status": "ERROR",
      "error": {
        "code": "RATE_LIMIT_EXCEEDED",
        "message": "API rate limit exceeded for Twitter API",
        "details": {
          "retry_after": 60,
          "limit": 100,
          "period": "1h"
        }
      },
      "original_request": {
        "query": "artificial intelligence advancements",
        "time_range": "last_30_days",
        "sources": ["twitter", "news", "blogs"]
      }
    }
  }
}
```

## Validation Rules

1. **Envelope Structure Validation**:
   - The envelope must contain all required fields (metadata, routing, security)
   - The metadata object must contain id, version, and timestamp
   - The routing object must contain source and destination objects
   - The security object must contain an auth_token

2. **Message ID Validation**:
   - Must be a valid UUID v4 format
   - Must be unique across the system
   - Used for deduplication and idempotency

3. **Version Validation**:
   - Must follow semantic versioning format (x.y.z)
   - Major version must be compatible with the system
   - Minor and patch versions should be handled gracefully

4. **Timestamp Validation**:
   - Must be a valid ISO8601 formatted string
   - Should be within an acceptable time window of current time (±5 minutes)
   - Used for message ordering and expiration checks

5. **Routing Validation**:
   - Source and destination agent_ids must be registered in the system
   - Service_ids must be associated with their respective agents
   - Reply_to channel must be a valid Pub/Sub topic or Supabase channel

6. **Security Validation**:
   - Auth_token must be a valid JWT
   - JWT must not be expired
   - JWT claims must authorize the source agent to perform the requested intent
   - Signature (if provided) must match the message content

7. **Message Type Validation**:
   - Must be one of the enumerated types
   - Message structure must be consistent with the declared type

8. **Intent Validation**:
   - Must be supported by the destination agent
   - Must be registered in the agent capability registry

## Related Schemas

- [A2A Protocol](../a2a-protocol.md): Comprehensive documentation of the A2A communication protocol
- [Task Schema](path/to/task-schema.md): Detailed schema for task payloads
- [Event Schema](path/to/event-schema.md): Detailed schema for event payloads
- [Error Schema](path/to/error-schema.md): Detailed schema for error responses

## Implementation Considerations

1. **Performance Considerations**:
   - The envelope adds overhead to each message (~0.5-1KB)
   - For high-throughput systems, consider envelope compression
   - Cache JWT verification results to reduce validation overhead
   - Use Pub/Sub ordered delivery for sequences requiring ordering

2. **Security Considerations**:
   - JWTs should have short expiration times (30-60 minutes)
   - Never include sensitive data in the envelope; use the encrypted payload
   - Rotate signing keys regularly
   - Consider adding signature verification for high-security environments
   - Implement tenant isolation for multi-tenant deployments

3. **Backward Compatibility**:
   - New optional fields can be added without breaking compatibility
   - Removal of fields requires a major version bump
   - Agents should gracefully handle unknown fields
   - Message processors should use schema validation with a "removeAdditional: false" setting

4. **Error Handling**:
   - Always respond to failed requests with proper error responses
   - Include the original request in error responses when possible
   - Use standardized error codes from the error schema
   - Return detailed error messages for debugging but sanitize sensitive information

5. **Distributed Tracing**:
   - Always propagate the trace_id across service boundaries
   - Use the correlation_id to link related messages
   - Consider integrating with OpenTelemetry for comprehensive tracing

## Changelog

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0.0 | 2025-01-15 | Initial version | API Team |
| 2.0.0 | 2025-03-10 | Added security.tenant_id, changed routing structure | API Team |
| 2.1.0 | 2025-04-22 | Added trace_id, expanded message types | API Team |

## References

- [JSON Schema Specification](https://json-schema.org/specification.html)
- [JWT RFC 7519](https://tools.ietf.org/html/rfc7519)
- [Google Cloud Pub/Sub Documentation](https://cloud.google.com/pubsub/docs)
- [Supabase Realtime Documentation](https://supabase.io/docs/reference/javascript/subscribe)
- [Internal A2A Protocol Design Document](path/to/internal/design-docs/a2a-protocol-design.md)

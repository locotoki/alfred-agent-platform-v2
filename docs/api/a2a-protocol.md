# Agent-to-Agent (A2A) Communication Protocol

*Last Updated: 2025-05-10*  
*Owner: API Team*  
*Status: Active*

## Overview

The Agent-to-Agent (A2A) Communication Protocol is the standardized messaging format that enables reliable, secure communication between agents in the Alfred Agent Platform. This protocol defines the message structure, transport mechanisms, reliability guarantees, and security measures that ensure agents can effectively collaborate while maintaining system integrity.

The A2A Protocol uses an envelope-based approach where all agent messages are wrapped in a consistent structure that includes metadata, routing information, security credentials, and the message payload. This design allows for message routing, tracing, authentication, and versioning across diverse agent implementations.

## Protocol Metadata

| Attribute | Value |
|-----------|-------|
| Version | 2.1.0 |
| Status | Active |
| Scope | Platform-wide |
| Backward Compatible | With v2.0.0+ |
| Transport Mechanisms | Google Cloud Pub/Sub (primary), Supabase Realtime (secondary) |
| Serialization | JSON |
| Schema Validation | Required |

## Message Envelope Structure

All A2A messages must conform to the following envelope structure:

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

### Envelope Metadata Fields

| Field | Description | Required | Format |
|-------|-------------|----------|--------|
| id | Unique message identifier | Yes | UUID v4 |
| version | Protocol version | Yes | Semantic version (x.y.z) |
| timestamp | Message creation time | Yes | ISO8601 (YYYY-MM-DDThh:mm:ss.sssZ) |
| correlation_id | ID linking related messages | No | UUID v4 |
| trace_id | Distributed tracing ID | No | UUID v4 or trace format |

### Routing Fields

| Field | Description | Required | Format |
|-------|-------------|----------|--------|
| source.agent_id | Originating agent identifier | Yes | String (max 64 chars) |
| source.service_id | Originating service identifier | Yes | String (max 64 chars) |
| destination.agent_id | Target agent identifier | Yes | String (max 64 chars) |
| destination.service_id | Target service identifier | No | String (max 64 chars) |
| reply_to | Response topic/channel | No | Valid topic name |

### Security Fields

| Field | Description | Required | Format |
|-------|-------------|----------|--------|
| auth_token | Authentication token | Yes | JWT |
| signature | Message signature | No | HMAC-SHA256 (Base64) |
| tenant_id | Multi-tenant identifier | No | String (max 64 chars) |

### Message Fields

| Field | Description | Required | Format |
|-------|-------------|----------|--------|
| type | Message classification | Yes | String enum (see Message Types) |
| intent | Specific operation requested | Yes | String enum (agent-specific) |
| payload | Message content | Yes | JSON object |

## Message Types

The A2A protocol supports the following message types:

| Type | Description | Transport Topic |
|------|-------------|----------------|
| TASK_REQUEST | Request for an agent to perform a task | a2a.tasks.create |
| TASK_RESPONSE | Response with task results | a2a.tasks.completed |
| EVENT | Notification of an occurrence | a2a.events |
| HEARTBEAT | Agent availability signal | a2a.heartbeats |
| DISCOVERY | Service discovery message | a2a.discovery |
| CONTROL | System control message | a2a.control |

## Intents

Intents are agent-specific and define the precise operation being requested. Each agent publishes its supported intents as part of the agent registration process. Common intents include:

### Social Intelligence Agent Intents
- TREND_ANALYSIS
- SOCIAL_MONITOR
- SENTIMENT_ANALYSIS

### Legal Compliance Agent Intents
- COMPLIANCE_CHECK
- REGULATION_SCAN
- POLICY_UPDATE_CHECK
- LEGAL_RISK_ASSESSMENT

### Financial-Tax Agent Intents
- FINANCIAL_ANALYSIS
- TAX_COMPLIANCE_CHECK
- FINANCIAL_FORECAST

## Transport Mechanisms

### Primary: Google Cloud Pub/Sub

The primary transport mechanism is Google Cloud Pub/Sub, which provides:
- At-least-once delivery guarantees
- Ordered message delivery (within a single region)
- High throughput and scalability
- Dead-letter queues for unprocessable messages

#### Topic Structure

Topics follow this naming convention:
```
a2a.[message_type].[optional_subtype]
```

For example:
- `a2a.tasks.create`
- `a2a.tasks.completed`
- `a2a.events.system`
- `a2a.heartbeats`

### Secondary: Supabase Realtime

For deployments where Google Cloud Pub/Sub is not available, the protocol supports Supabase Realtime as a secondary transport mechanism. It provides:
- WebSocket-based real-time communication
- Database-backed persistence
- Channel-based message routing

#### Channel Structure

Channels follow this naming convention:
```
a2a:[message_type]:[optional_subtype]
```

## Error Handling

The A2A protocol defines standardized error responses for handling failures:

```json
{
  "envelope": { /* standard envelope */ },
  "message": {
    "type": "TASK_RESPONSE",
    "intent": "[original intent]",
    "payload": {
      "status": "ERROR",
      "error": {
        "code": "string",
        "message": "string",
        "details": {}
      },
      "original_request": {}
    }
  }
}
```

### Error Codes

| Code | Description | HTTP Equivalent |
|------|-------------|----------------|
| INVALID_REQUEST | Malformed request | 400 |
| UNAUTHORIZED | Authentication failed | 401 |
| FORBIDDEN | Authorization failed | 403 |
| NOT_FOUND | Requested resource not found | 404 |
| INTENT_NOT_SUPPORTED | Agent doesn't support the intent | 405 |
| TIMEOUT | Processing timed out | 408 |
| INTERNAL_ERROR | Agent internal error | 500 |
| SERVICE_UNAVAILABLE | Agent service unavailable | 503 |

## Reliability Patterns

### Exactly-Once Processing

To achieve exactly-once processing semantics:

1. Message producers assign a unique ID to each message
2. Message consumers maintain a processed-message log
3. Consumers check for duplicate message IDs before processing
4. Consumers use idempotent operations where possible

### Dead-Letter Queue

Messages that cannot be processed after multiple attempts are sent to a dead-letter queue:
```
a2a.deadletter
```

These messages include the original message plus error information:

```json
{
  "original_message": {},
  "error_info": {
    "attempts": 5,
    "last_error": "string",
    "last_attempt_timestamp": "ISO8601 datetime"
  }
}
```

## Security Considerations

### Authentication

All A2A messages must include a valid JWT in the `envelope.security.auth_token` field. This token must:
- Be issued by the platform's authentication service
- Include the source agent's identity in the claims
- Not be expired
- Have the appropriate scope for the requested operation

### Authorization

Agents must validate that the source agent has permission to:
1. Send messages to the destination agent
2. Request the specific intent
3. Access any resources referenced in the payload

### Payload Encryption

Sensitive data within the payload should be encrypted using:
1. The platform's encryption service
2. AES-256-GCM encryption
3. Recipient agent's public key (when using asymmetric encryption)

## Service Discovery

Agents register their capabilities and intents in the agent registry. To discover agents:

1. Send a DISCOVERY message to `a2a.discovery`
2. Query the agent registry table in Supabase
3. Cache discovery results with a 60-second TTL

Example discovery response:

```json
{
  "envelope": { /* standard envelope */ },
  "message": {
    "type": "DISCOVERY",
    "intent": "REGISTRY_RESPONSE",
    "payload": {
      "agents": [
        {
          "agent_id": "social-intelligence-agent",
          "service_id": "social-intelligence-service",
          "supported_intents": ["TREND_ANALYSIS", "SOCIAL_MONITOR", "SENTIMENT_ANALYSIS"],
          "endpoint": "a2a.tasks.create",
          "version": "1.2.0",
          "status": "ACTIVE"
        }
      ]
    }
  }
}
```

## Versioning

The A2A protocol follows semantic versioning:
- Major version changes (e.g., 1.x to 2.x) may break compatibility
- Minor version changes (e.g., 2.1 to 2.2) add features in a backward-compatible way
- Patch version changes (e.g., 2.1.0 to 2.1.1) fix bugs in a backward-compatible way

Agents should specify the minimum protocol version they require and handle messages from newer minor/patch versions gracefully.

## Implementation Examples

### Python Implementation

```python
import uuid
import json
import time
import jwt
import asyncio
from google.cloud import pubsub_v1

class A2AProtocol:
    def __init__(self, agent_id, service_id, auth_token):
        self.agent_id = agent_id
        self.service_id = service_id
        self.auth_token = auth_token
        self.publisher = pubsub_v1.PublisherClient()
        
    def create_envelope(self, destination_agent, destination_service=None):
        """Create a standard A2A envelope"""
        return {
            "metadata": {
                "id": str(uuid.uuid4()),
                "version": "2.1.0",
                "timestamp": time.strftime('%Y-%m-%dT%H:%M:%S.000Z', time.gmtime()),
                "correlation_id": str(uuid.uuid4()),
                "trace_id": str(uuid.uuid4())
            },
            "routing": {
                "source": {
                    "agent_id": self.agent_id,
                    "service_id": self.service_id
                },
                "destination": {
                    "agent_id": destination_agent,
                    "service_id": destination_service
                },
                "reply_to": f"a2a.tasks.completed.{self.agent_id}"
            },
            "security": {
                "auth_token": self.auth_token,
                "signature": None,
                "tenant_id": "default"
            }
        }
    
    def create_task_request(self, destination_agent, intent, payload, destination_service=None):
        """Create a task request message"""
        envelope = self.create_envelope(destination_agent, destination_service)
        message = {
            "type": "TASK_REQUEST",
            "intent": intent,
            "payload": payload
        }
        return {"envelope": envelope, "message": message}
    
    async def send_message(self, message, topic):
        """Send a message to the specified topic"""
        topic_path = self.publisher.topic_path("project-id", topic)
        message_json = json.dumps(message).encode("utf-8")
        future = self.publisher.publish(topic_path, message_json)
        return await future
```

### JavaScript Implementation

```javascript
const { PubSub } = require('@google-cloud/pubsub');
const { v4: uuidv4 } = require('uuid');
const jwt = require('jsonwebtoken');

class A2AProtocol {
  constructor(agentId, serviceId, authToken) {
    this.agentId = agentId;
    this.serviceId = serviceId;
    this.authToken = authToken;
    this.pubsub = new PubSub();
  }
  
  createEnvelope(destinationAgent, destinationService = null) {
    return {
      metadata: {
        id: uuidv4(),
        version: '2.1.0',
        timestamp: new Date().toISOString(),
        correlation_id: uuidv4(),
        trace_id: uuidv4()
      },
      routing: {
        source: {
          agent_id: this.agentId,
          service_id: this.serviceId
        },
        destination: {
          agent_id: destinationAgent,
          service_id: destinationService
        },
        reply_to: `a2a.tasks.completed.${this.agentId}`
      },
      security: {
        auth_token: this.authToken,
        signature: null,
        tenant_id: 'default'
      }
    };
  }
  
  createTaskRequest(destinationAgent, intent, payload, destinationService = null) {
    const envelope = this.createEnvelope(destinationAgent, destinationService);
    const message = {
      type: 'TASK_REQUEST',
      intent: intent,
      payload: payload
    };
    return { envelope, message };
  }
  
  async sendMessage(message, topic) {
    const messageJson = JSON.stringify(message);
    const messageBuffer = Buffer.from(messageJson);
    const messageId = await this.pubsub.topic(topic).publish(messageBuffer);
    return messageId;
  }
}
```

## Testing and Validation

### Message Validation

Validate A2A messages using the JSON schema provided at `/docs/schemas/a2a-envelope-schema.json`. Example validation:

```python
import jsonschema
import json

# Load schema
with open('/docs/schemas/a2a-envelope-schema.json', 'r') as f:
    schema = json.load(f)

# Validate message
try:
    jsonschema.validate(message, schema)
    print("Message is valid")
except jsonschema.exceptions.ValidationError as e:
    print(f"Message validation error: {e}")
```

### Testing Endpoints

For testing A2A protocol implementations, use:

1. The emulator endpoint for local development:
   ```
   localhost:8085/v1/projects/test-project/topics/a2a.tasks.create
   ```

2. The test environment endpoint for integration testing:
   ```
   pubsub.googleapis.com/v1/projects/test-project/topics/a2a.tasks.create
   ```

## Related Documentation

- [Agent Registry API](../api/agent-registry.md)
- [Pub/Sub Configuration Guide](../operations/pubsub-configuration.md)
- [Security Implementation Guide](../architecture/security-architecture.md)
- [Agent Development Guide](../agents/guides/agent-implementation-guide.md)

## References

- [Google Cloud Pub/Sub Documentation](https://cloud.google.com/pubsub/docs)
- [Supabase Realtime Documentation](https://supabase.io/docs/reference/javascript/subscribe)
- [JWT Authentication Standard](https://tools.ietf.org/html/rfc7519)
- [JSON Schema Specification](https://json-schema.org/specification.html)